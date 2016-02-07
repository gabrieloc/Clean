//
//  Character.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

enum GroundType : Int {
	case InTheAir
	case Surface
}

enum Action : Int {
	case Idle
	case Walk
	case Lift
	case Drop
}

class Character {
	
	init() {
		let initialSceneName = sceneNameForAction(currentAction)
		let characterScene = SCNScene(named: initialSceneName)!
		let characterTopLevelNode = characterScene.rootNode.childNodes[0]
		node.addChildNode(characterTopLevelNode)
		
		let (min, max) = node.boundingBox
		let collisionCapsuleRadius = CGFloat(max.x - min.x) * 0.4
		let collisionCapsuleHeight = self.height()
		
		let collidorGeometry = SCNCapsule(capRadius: collisionCapsuleRadius, height: collisionCapsuleHeight)
		let characterCollisionNode = SCNNode()
		characterCollisionNode.name = "collision"
		characterCollisionNode.position = SCNVector3(0.0, collisionCapsuleHeight * 0.51, 0.0)
		characterCollisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape:SCNPhysicsShape(geometry: collidorGeometry, options:nil))
		characterCollisionNode.physicsBody!.contactTestBitMask = BitmaskCollision | BitmaskLiftable
		node.addChildNode(characterCollisionNode)
	}

	let node = SCNNode()
	var lifting: LiftableObject?
	
	var dropzone : Dropzone!
	var dropZoneVisible: Bool = false {
		didSet {
			if dropZoneVisible && dropzone == nil {
				dropzone = Dropzone()
				node.addChildNode(dropzone)
			} else if dropzone != nil {
				dropzone.removeFromParentNode()
				dropzone = nil
			}
		}
	}
	
	// MARK: Movement
	
	static let speedFactor = Float(3.0)
	private var groundType = GroundType.InTheAir
	private var previousUpdateTime = NSTimeInterval(0.0)
	private var accelerationY = SCNFloat(0.0) // gravity simulation

	private var directionAngle: SCNFloat = 0.0 {
		didSet {
			if directionAngle != oldValue {
				let rotation = SCNAction.rotateToX(0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.2, shortestUnitArc: true)
				node.runAction(rotation)
				lifting?.runAction(rotation)
			}
		}
	}
	
	func height() -> CGFloat {
//		let (min, max) = node.boundingBox
//		return max.y - min.y
		return 1.0
	}
	
	func length() -> CGFloat {
		let (min, max) = node.boundingBox
		return max.z - min.z
	}
	
	func walkInDirection(direction: float3, time: NSTimeInterval, scene: SCNScene) -> SCNNode? {
		
		if currentAction == .Lift || currentAction == .Drop {
			return nil
		}
		
		if previousUpdateTime == 0.0 {
			previousUpdateTime = time
		}
	
		let deltaTime = Float(min(time - previousUpdateTime, 1.0 / 60.0))
		let characterSpeed = deltaTime * Character.speedFactor
		previousUpdateTime = time
		
		// move
		if (direction.x != 0.0 || direction.z != 0.0) {
			var position = node.position
			node.position = SCNVector3(float3(position) + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
			
			if isLifting {
				lifting?.runAction(SCNAction.moveTo(positionForLiftedObject(lifting!), duration: 0))
			}
			
			var p0 = position
			var p1 = position
			
			let maxRise = SCNFloat(0.08)
			let maxJump = SCNFloat(10.0)
			p0.y -= maxJump
			p1.y += maxRise
			
			// Do a vertical ray intersection
			var groundNode: SCNNode?
			let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p1, toPoint: p0, options:[SCNPhysicsTestCollisionBitMaskKey: BitmaskCollision, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])
			
			if let result = results.first {
				var groundAltitude = result.worldCoordinates.y
				groundNode = result.node
				
				let groundMaterial = result.node.childNodes[0].geometry!.firstMaterial!
//				groundType = groundTypeFromMaterial(groundMaterial)
				
				let threshold = SCNFloat(1e-5)
				let gravityAcceleration = SCNFloat(0.18)
				
				if groundAltitude < position.y - threshold {
					accelerationY += SCNFloat(deltaTime) * gravityAcceleration // approximation of acceleration for a delta time.
//					if groundAltitude < position.y - 0.2 {
//						groundType = .InTheAir
//					}
				}
				else {
					accelerationY = 0
				}
				
				position.y -= accelerationY
				
				// reset acceleration if we touch the ground
				if groundAltitude > position.y {
					accelerationY = 0
					position.y = groundAltitude
				}
				
				// Finally, update the position of the character.
				node.position = position
			}
			
			transitionToAction(.Walk)
		}
		else {
			transitionToAction(.Idle)
		}

		return nil
	}
	
	// MARK: Animations
	
	var currentAction: Action = .Idle
	func transitionToAction(action: Action) {
		let key = identifierForAction(action)
		if node.animationForKey(key) == nil  {
			currentAction = action
//			print(key)
			node.addAnimation(characterAnimationForAction(action), forKey: key)
			for oldKey in node.animationKeys {
				if oldKey != key {
					node.removeAnimationForKey(oldKey, fadeOutDuration: transitionDurationForAction(action))
				}
			}
		}
	}
	
	private func identifierForAction(action: Action) -> String {
		switch(action) {
		case .Idle:
			return isLifting ? "idle-lifting" : "idle"
		case .Walk:
			return isLifting ? "walk-lifting" : "walk"
		case .Lift:
			return "lift"
		case .Drop:
			return "drop"
		}
	}
	
	private func sceneNameForAction(action : Action) -> String {
		let identifier = identifierForAction(action)
		return "game.scnassets/baby/\(identifier).scn"
	}
	
	func transitionDurationForAction(action: Action) -> CGFloat {
		if action == .Idle && isLifting {
			return 0.1
		} else if action == .Lift || action == .Drop {
			return 0.01
		} else {
			return 0.2
		}
	}
	
	func characterAnimationForAction(action: Action) -> CAAnimation {
		let name = sceneNameForAction(action)
		let animation = CAAnimation.animationWithSceneNamed(name)!
		animation.fadeInDuration = transitionDurationForAction(action)
		
		if action != .Lift && action != .Drop {
			animation.repeatCount = Float.infinity
		}
	
		if action == .Walk {
			animation.speed = Character.speedFactor
		}
		
		return animation
	}
	
	// MARK: Sound
	
	private func playFootStep() {
		//TODO
	}
}
