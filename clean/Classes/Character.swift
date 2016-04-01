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
		let collisionCapsuleWidth = CGFloat(max.x - min.x) * 0.6
		let collisionCapsuleHeight = CGFloat(self.height())
		let collisionCapsuleLength = CGFloat(max.x - min.x) * 0.3
		
		let collidorGeometry = SCNBox(width: collisionCapsuleWidth, height: collisionCapsuleHeight, length: collisionCapsuleLength, chamferRadius: 0)
		let characterCollisionNode = SCNNode()
		characterCollisionNode.name = "collision"
		characterCollisionNode.position = SCNVector3(0.0, collisionCapsuleHeight * 0.51, 0.0)
		characterCollisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape:SCNPhysicsShape(geometry: collidorGeometry, options:nil))
		characterCollisionNode.physicsBody!.contactTestBitMask = BitmaskCollision | BitmaskLiftable | BitmaskDrivable
		node.addChildNode(characterCollisionNode)
	}
	
	let node: SCNNode
	var lifting: LiftableObject?
	var driving: Vehicle?
	var vehicleEntrance: VehicleEntrance = .None
	
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
	private var isFalling = false
	
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
		let height = Float(max.y - min.y)
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
		return isFacingObjectWithCollisionBitMaskKey(BitmaskCollision, scene: scene)
	}
	
	func isFacingLiftableObject(scene: SCNScene) -> Bool {
		return isFacingObjectWithCollisionBitMaskKey(BitmaskLiftable, scene: scene)
	}
	
	func isFacingObjectWithCollisionBitMaskKey(bitMaskKey: Int, scene: SCNScene) -> Bool {
		let p0 = node.position
		let p1 = node.convertPosition(SCNVector3(0, 0, self.length()), toNode: nil)
		let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p0, toPoint: p1, options: [SCNPhysicsTestCollisionBitMaskKey: bitMaskKey, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])
		return results.count > 0
	}
	
	func moveInDirection(direction: float3, time: NSTimeInterval, scene: SCNScene) {
		
		if currentAction == .Lift || currentAction == .Drop || currentAction == .Jump {
			return
		}
		
		let deltaTime: NSTimeInterval = min(time - previousUpdateTime, 1.0 / 60.0)
		previousUpdateTime = time
		
		
		if isDriving() {
			driveInDirection(direction, deltaTime: deltaTime)
		} else {
			walkInDirection(direction, deltaTime: deltaTime)
		}
		
		updateAltitude(scene, deltaTime: deltaTime)
	}
	
	private var vehicleAcceleration: Float = 0.0
	private func driveInDirection(direction: float3, deltaTime: NSTimeInterval) {
		
		let acceleration: Float = 0.15
		vehicleAcceleration += Float(deltaTime) * acceleration
		vehicleAcceleration = min(vehicleAcceleration, 50.0)
		
		node.position = SCNVector3(float3(node.position) + direction * vehicleAcceleration)
	}
	
	private func walkInDirection(direction: float3, deltaTime: NSTimeInterval) {
		
		let characterSpeed = Float(deltaTime) * Character.speedFactor
		let isWalking = direction.x != 0.0 || direction.z != 0.0
		
		if (isWalking) {
			node.position = SCNVector3(float3(node.position) + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
		}
		
		lifting?.position = positionForLiftedObject(lifting!)
		
		if isFalling {
			transitionToAction(.Fall)
		} else if isWalking {
			transitionToAction(.Walk)
		} else {
			transitionToAction(.Idle)
		}
	}
	
	private func updateAltitude(scene: SCNScene, deltaTime: NSTimeInterval) {
		
		var position = node.position
		print(position)
		
		var p0 = position
		var p1 = position
		
		let maxRise = SCNFloat(10.0)
		let maxJump = SCNFloat(10.0)
		p0.y -= maxJump
		p1.y += maxRise
		
		let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p1, toPoint: p0, options:[SCNPhysicsTestCollisionBitMaskKey: BitmaskCollision, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])
		
		if let result = results.first {
			let groundAltitude = result.worldCoordinates.y
			let threshold = SCNFloat(1e-5)
			let gravityAcceleration = SCNFloat(0.18)
			
			if groundAltitude < position.y - threshold {
				accelerationY += SCNFloat(deltaTime) * gravityAcceleration // approximation of acceleration for a delta time.
				if groundAltitude < position.y - 0.2 { // transition to falling if ground is more than 0.2 away
					groundType = .InTheAir
					isFalling = true
				} else {
					isFalling = false
				}
			}
			else {
				accelerationY = 0
			}
			position.y -= accelerationY
			if groundAltitude > position.y {
				accelerationY = 0
				position.y = groundAltitude
			}
			node.position = position
		}
	}
	
	// MARK: Animations
	
	func identifierForNewAction(action: Action) -> String {
		if action == .Drive {
			return action.drivingIdentifier(isDriving(), entrance: vehicleEntrance)
		} else {
			return action.identifier(isLifting)
		}
	}
	
	var currentAction: Action = .Idle
	func transitionToAction(action: Action) {
		let key = identifierForNewAction(action)
		if node.animationForKey(key) == nil  {
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
		let name = identifierForNewAction(action)
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
