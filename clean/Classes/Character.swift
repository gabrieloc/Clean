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

protocol CharacterDelegate: NSObjectProtocol {
	func character(character: Character, willTransitionToAction: Action)
	func character(character: Character, didFinishInteractingWithObject: AnyObject)
}

class Character {
	
	init() {
		let characterScene = SCNScene(named: currentAction.identifier())!
		node = characterScene.rootNode
		
		let (min, max) = node.boundingBox
		let collisionCapsuleWidth = CGFloat(max.x - min.x)
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
	var delegate: CharacterDelegate?
	
	var interactable: AnyObject?
	var lifting: LiftableObject? {
		didSet {
			interactable = lifting
		}
	}
	internal var dropForceTimer: NSTimer = NSTimer()
	var driving: Vehicle? {
		didSet {
			interactable = driving
		}
	}
	var storedEntrance: VehicleEntrance = .None
	var adjustingFlatbed: Bool = false
	
	// MARK: Movement
	
	static let speedFactor = Float(3.0)
	private var groundType = GroundType.InTheAir
	private var previousUpdateTime = NSTimeInterval(0.0)
	private var accelerationY: Float = 0.0 // gravity simulation
	internal var vehicleAcceleration: Float = 0.0
	internal var vehicleDirectionAngle: Float = 0.0
	internal var vehicleSteerDelta: Float = 0.0
	private var isFalling = false
	
	// Angle in degrees
	internal var directionAngleDegrees: Float = 0.0 {
		didSet {
			if directionAngleDegrees != oldValue {
				updateDirection()
			}
		}
	}
	
	internal func updateDirection() {
		updateDirectionAnimated(true)
	}
	
	internal func updateDirectionAnimated(animated: Bool) {
		
		let directionRadians: CGFloat = CGFloat(directionAngleDegrees.degreesToRadians)
		
		if isDriving {
			let characterRotation = SCNAction.rotateToX(0, y: directionRadians - SCNFloat(M_PI_2), z: 0, duration: 0, shortestUnitArc: true)
			node.runAction(characterRotation)
			driving!.directionAngle = CGFloat(directionAngleDegrees)
		}
		else {
			let duration = animated ? 0.2 : 0.0
			let rotation = SCNAction.rotateToX(0.0, y: directionRadians, z: 0.0, duration: duration, shortestUnitArc: true)
			node.runAction(rotation)
			lifting?.runAction(rotation)
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
	
	func directionalInputChanged(input: float2, pov: SCNNode, time: NSTimeInterval, scene: SCNScene) {
		
		if currentAction == .Lift || currentAction == .Drop || currentAction == .Jump {
			return
		}
		
		let deltaTime: NSTimeInterval = min(time - previousUpdateTime, 1.0 / 60.0)
		previousUpdateTime = time
		
		if isDriving {
			var speed = input.y
			if adjustingFlatbed {
				adjustFlatbed(input.y, deltaTime: deltaTime)
				speed = 0
			}
			driveInDirection(input.x, speed: speed, deltaTime: deltaTime)
		}
		else {
			let directionalInput = float3(input.x, 0.0, input.y)
			let direction = convertInputDirection(directionalInput, cameraNode: pov)
			walkInDirection(direction, deltaTime: deltaTime)
			updateAltitude(scene, deltaTime: deltaTime)
		}
	}
	
	func actionInput(input: ActionInput, selected: Bool) {
		
		switch input {
		case .ButtonA:

			if isDriving && selected {
				self.endDriving(driving!)
			}
			else if isLifting {
				dropInputSelected(selected)
			}
			else if selected {
				self.useInteractable(interactable)
			}
		case .ButtonB:
			if isDriving {
				adjustingFlatbed = selected
			}
		}
	}
	
	internal func useInteractable(interactable: AnyObject?) {
		if let liftable = interactable as? LiftableObject {
			self.liftObject(liftable)
		}
		else if let vehicle = interactable as? Vehicle {
			self.beginDrivingVehicle(vehicle, entrance: storedEntrance)
		}
	}
	
	private func convertInputDirection(direction: float3, cameraNode: SCNNode) -> float3 {
		// Convert input coordinates into 3d
		let p1 = cameraNode.convertPosition(SCNVector3(direction), toNode: nil)
		let p0 = cameraNode.convertPosition(SCNVector3Zero, toNode: nil)
		var convertedDirection = float3(Float(p1.x - p0.x), 0.0, Float(p1.z - p0.z))
		
		if convertedDirection.x != 0.0 || convertedDirection.y != 0.0 {
			convertedDirection = normalize(convertedDirection)
		}
		return convertedDirection
	}
	
	private func walkInDirection(direction: float3, deltaTime: NSTimeInterval) {
		
		let characterSpeed = Float(deltaTime) * Character.speedFactor
		let isWalking = direction.x != 0.0 || direction.z != 0.0
		
		if (isWalking) {
			node.position = SCNVector3(float3(node.position) + direction * characterSpeed)
			directionAngleDegrees = atan2(direction.x, direction.z).radiansToDegrees
			updateDirection()
		}
		
		lifting?.position = positionForLiftedObject(lifting!)
		
		var newAction: Action
		
		if isFalling {
			newAction = .Fall
		}
		else if isWalking {
			newAction = .Walk
		}
		else {
			newAction = .Idle
		}
		
		if currentAction != newAction {
			transitionToAction(newAction)
		}
	}
	
	private func updateAltitude(scene: SCNScene, deltaTime: NSTimeInterval) {
		
		var position = node.position
		
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
			let gravityAcceleration: Float = 0.18
			
			if groundAltitude < position.y - threshold {
				accelerationY += Float(deltaTime) * gravityAcceleration
				isFalling = groundAltitude < position.y - 0.2
				groundType = isFalling ? .InTheAir : .Surface
			}
			else {
				accelerationY = 0
				position.y = groundAltitude
			}
			position.y -= SCNFloat(accelerationY)
			print(position.y)
			
			node.position = position
		}
	}
	
	// MARK: Animations
	
	func identifierForNewAction(action: Action) -> String {
		if action == .EnterVehicle || action == .ExitVehicle {
			return action.identiferForNewVehicleAction(action, entrance: storedEntrance)
		} else {
			return action.identifier(isLifting)
		}
	}
	
	var currentAction: Action = .Idle
	
	func transitionToAction(action: Action) {
		transitionToAction(action, completion: nil)
	}
	
	func transitionToAction(action: Action, completion: (() -> Void)?) {
		
		delegate?.character(self, willTransitionToAction: action)
		
		let key = identifierForNewAction(action)
		if node.animationForKey(key) == nil  {
			SCNTransaction.begin()
			SCNTransaction.setCompletionBlock({
				completion?()
			})
			node.addAnimation(characterAnimationForAction(action), forKey: key)
			SCNTransaction.commit()
			
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
//		animation.fadeOutDuration = 0.5
		animation.fillMode = kCAFillModeForwards
		animation.removedOnCompletion = false
		
		let seamlessAnimations: [Action] = [.Idle, .Walk]
		animation.repeatCount = seamlessAnimations.contains(action) ? Float.infinity : 1.0
		
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
