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

class Character {
	
	init() {
		let characterScene = SCNScene(named: currentAction.identifier())!
		node = characterScene.rootNode
		
		let (min, max) = node.boundingBox
		let collisionCapsuleRadius = CGFloat(max.x - min.x) * 0.4
		let collisionCapsuleHeight = CGFloat(self.height())
		
		let collidorGeometry = SCNCapsule(capRadius: collisionCapsuleRadius, height: collisionCapsuleHeight)
		let characterCollisionNode = SCNNode()
		characterCollisionNode.name = "collision"
		characterCollisionNode.position = SCNVector3(0.0, collisionCapsuleHeight * 0.51, 0.0)
		characterCollisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape:SCNPhysicsShape(geometry: collidorGeometry, options:nil))
		characterCollisionNode.physicsBody!.contactTestBitMask = BitmaskCollision | BitmaskLiftable
		node.addChildNode(characterCollisionNode)
	}
	
	let node: SCNNode
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
	
	func height() -> Float {
		let (min, max) = node.boundingBox
		var height = Float(max.y - min.y)
		height += isLifting ? 0.1 : 0.0
		return height
	}
	
	func length() -> Float {
		// TODO: properly calculate depth based off collider geometry
		return height()
	}
	
	func jumpToPosition(desiredPosition: SCNVector3) {
		let elevation = desiredPosition.y - node.position.y
		if currentAction != .Jump && elevation > 0.25 {
			print(elevation)
			var peakPosition = desiredPosition
			peakPosition.y += elevation * 0.2
			
			let prep = SCNAction.waitForDuration(NSTimeInterval(elevation * 0.1))
			let jumping = SCNAction.moveTo(peakPosition, duration: NSTimeInterval(elevation * 0.2))
			jumping.timingMode = SCNActionTimingMode.EaseOut
			let landing = SCNAction.moveTo(desiredPosition, duration: NSTimeInterval(elevation * 0.1))
			landing.timingMode = SCNActionTimingMode.EaseOut
			let action = SCNAction.sequence([prep, jumping, landing])
			node.runAction(action, completionHandler: { () -> Void in
				self.transitionToAction(.Walk)
			})
			transitionToAction(.Jump)
		}
	}
	
	func isFacingWall(scene: SCNScene) -> Bool {
		let p0 = node.position
		let p1 = node.convertPosition(SCNVector3Make(0, 0, 1), toNode: nil)
		let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p0, toPoint: p1, options: [SCNPhysicsTestCollisionBitMaskKey: BitmaskCollision, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])
		return results.count > 0
	}
	
	func walkInDirection(direction: float3, time: NSTimeInterval, scene: SCNScene) -> SCNNode? {

		if currentAction == .Lift || currentAction == .Drop || currentAction == .Jump {
			return nil
		}
		
		if previousUpdateTime == 0.0 {
			previousUpdateTime = time
		}
		
		let deltaTime = Float(min(time - previousUpdateTime, 1.0 / 60.0))
		let characterSpeed = deltaTime * Character.speedFactor
		previousUpdateTime = time
		
		let isWalking = direction.x != 0.0 || direction.z != 0.0
		var isFalling = false //TODO

		if (isWalking) {
			node.position = SCNVector3(float3(node.position) + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
		}
		
		
		lifting?.runAction(SCNAction.moveTo(positionForLiftedObject(lifting!), duration: 0))

		var position = node.position

		var p0 = position
		var p1 = position
		
		let maxRise = SCNFloat(10.0)
		let maxJump = SCNFloat(10.0)
		p0.y -= maxJump
		p1.y += maxRise
		
		// Do a vertical ray intersection
		let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p1, toPoint: p0, options:[SCNPhysicsTestCollisionBitMaskKey: BitmaskCollision, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])

		if let result = results.first {
			let groundAltitude = result.worldCoordinates.y
			let threshold = SCNFloat(1e-5)
			let gravityAcceleration = SCNFloat(0.18)
			
//			print(groundAltitude)
			
			if groundAltitude < position.y - threshold {
//				print(groundAltitude, position.y)
				accelerationY += SCNFloat(deltaTime) * gravityAcceleration // approximation of acceleration for a delta time.
				if groundAltitude < position.y - 0.2 { // transition to falling if ground is more than 0.2 away
					groundType = .InTheAir
					isFalling = true
				}
			}
			else {
				accelerationY = 0
			}
			
			position.y -= accelerationY
//			print(accelerationY)
			
			// reset acceleration if we touch the ground
			if groundAltitude > position.y {
				accelerationY = 0
				position.y = groundAltitude
			}
			
//			print(accelerationY)
			// Finally, update the position of the character.
			node.position = position
		}
		
		node.position = position
		
		if isFalling {
			transitionToAction(.Fall)
		} else if isWalking {
			transitionToAction(.Walk)
		} else {
			transitionToAction(.Idle)
		}
		
		return nil
	}
	
	// MARK: Animations
	
	var currentAction: Action = .Idle
	func transitionToAction(action: Action) {
		let key = action.identifier(isLifting)
		if node.animationForKey(key) == nil  {
			print(key)
			node.addAnimation(characterAnimationForAction(action), forKey: key)
			for oldKey in node.animationKeys {
				if oldKey != key {
					node.removeAnimationForKey(oldKey, fadeOutDuration: action.transitionDurationFromAction(currentAction, isLifting: isLifting))
				}
			}
			currentAction = action
		}
	}
	
	func characterAnimationForAction(action: Action) -> CAAnimation! {
		let name = action.identifier(isLifting)
		let animation = CAAnimation.animationWithSceneNamed(name)!
		animation.fadeInDuration = action.transitionDurationFromAction(currentAction, isLifting: isLifting)
		
		if action != .Lift && action != .Drop && action != .Jump && action != .Fall {
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
