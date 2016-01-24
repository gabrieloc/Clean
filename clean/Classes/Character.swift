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
	
	// MARK: Lifting
	
	var liftingOriginalPosition: SCNVector3?
	var lifting: SCNNode! {
		willSet {
			if isLifting {
				let offset = node.convertPosition(SCNVector3Make(0, 0, 2), toNode: lifting)
				let liftedFinalPosition = SCNVector3Make(lifting.position.x + offset.x, 1, lifting.position.z + offset.z)
				lifting.position = liftedFinalPosition
			}
		}
		didSet {
			dropZoneVisible = isLifting
			if isLifting {
				liftingOriginalPosition = lifting.position
			}
		}
	}

	var isLifting : Bool {
		get {
			return lifting != nil
		}
	}
	
	var dropzone : Dropzone!
	var dropZoneVisible: Bool = false {
		didSet {
			if dropZoneVisible {
				dropzone = Dropzone()
				node.addChildNode(dropzone)
			} else {
				dropzone.removeFromParentNode()
			}
		}
	}
	
	func dropObject() {
		lifting = nil
		transitionToAction(.Idle)
	}
	
	func liftObject(object: SCNNode) {
		lifting = object
		transitionToAction(.Lift)
	}
	
	// MARK: Movement
	
	static let speedFactor = Float(3.0)
	private var groundType = GroundType.InTheAir
	private var previousUpdateTime = NSTimeInterval(0.0)
	private var accelerationY = SCNFloat(0.0) // gravity simulation

	private var directionAngle: SCNFloat = 0.0 {
		didSet {
			if directionAngle != oldValue {
				node.runAction(SCNAction.rotateToX(0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.2, shortestUnitArc: true))
			}
		}
	}
	
	func height() -> CGFloat {
		let (min, max) = node.boundingBox
		return max.y - min.y
	}
	
	func walkInDirection(direction: float3, time: NSTimeInterval, scene: SCNScene) -> SCNNode? {
		if previousUpdateTime == 0.0 {
			previousUpdateTime = time
		}
	
		let deltaTime = Float(min(time - previousUpdateTime, 1.0 / 60.0))
		let characterSpeed = deltaTime * Character.speedFactor
		previousUpdateTime = time
		
		// move
		if (direction.x != 0.0 || direction.z != 0.0) && currentAction != .Lift {
			let position = float3(node.position)
			node.position = SCNVector3(position + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
			
			if lifting != nil {
				let (min, max) = (lifting?.boundingBox)!
				let liftingObjectHeight = max.y - min.y
				let objectY = self.height() + liftingObjectHeight
				let liftingObjectPosition = SCNVector3Make(CGFloat(position.x), objectY, CGFloat(position.z))
				lifting?.position = liftingObjectPosition
			}
			
			isWalking = true
		}
		else {
			isWalking = false
		}

		return nil
	}
	
	// MARK: Animations
	
	var currentAction: Action = .Idle
	private func transitionToAction(action: Action) {
		let key = identifierForAction(action)
		if node.animationForKey(key) == nil  {
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
	
	private func transitionDurationForAction(action: Action) -> CGFloat {
		if action == .Idle && isLifting {
			return 0.2
		} else {
			return 0.5
		}
	}
	
	func characterAnimationForAction(action: Action) -> CAAnimation {
		let name = sceneNameForAction(action)
		let animation = CAAnimation.animationWithSceneNamed(name)!
		animation.fadeInDuration = transitionDurationForAction(action)
		
		if action != .Lift {
			animation.repeatCount = Float.infinity
		}
		
		if action == .Walk {
			animation.speed = Character.speedFactor
		}
		
		return animation
	}

	private var isWalking: Bool = false {
		didSet {
			if oldValue != isWalking {
				if isWalking {
					transitionToAction(.Walk)
				} else {
					transitionToAction(.Idle)
				}
			}
		}
	}
	
	// MARK: Sound
	
	private func playFootStep() {
		//TODO
	}
}
