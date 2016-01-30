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
	
	func liftObject(object:LiftableObject) {
		if lifting != nil {
			return
		}
		 
		let desiredLiftingPosition = positionForLiftedObject(object)
		
		SCNTransaction.begin()
		SCNTransaction.setAnimationDuration(0.3)
		SCNTransaction.setCompletionBlock({
			self.lifting = object
			self.transitionToAction(.Idle)
		})
		
		transitionToAction(.Lift)
		let liftingObjectAnimation = animationForLiftedObject(object, position:desiredLiftingPosition, duration:0.2, delay:0.1)
		object.position = desiredLiftingPosition
		object.addAnimation(liftingObjectAnimation, forKey: "lift")
		
		SCNTransaction.commit()
	}
	
	func dropObject() {
		if lifting == nil {
			return
		}
		
		let object = lifting!
		
		let desiredDroppedPosition = positionForDroppedObject(object)
		
		SCNTransaction.begin()
		SCNTransaction.setAnimationDuration(0.3)
		SCNTransaction.setCompletionBlock({
			self.lifting = nil
			self.transitionToAction(.Idle)
		})
		
		transitionToAction(.Drop)
		
		let droppingObjectAnimation = animationForLiftedObject(object, position:desiredDroppedPosition, duration:0.4, delay:0)
		object.position = desiredDroppedPosition
		object.addAnimation(droppingObjectAnimation, forKey: "drop")
		
		SCNTransaction.commit()
	}

	var isLifting : Bool {
		get {
			return lifting != nil
		}
	}
	private var lifting: LiftableObject?
	
	func animationForLiftedObject(object: SCNNode, position: SCNVector3, duration: Double, delay: NSTimeInterval) -> CAAnimation {
		let animation = CAKeyframeAnimation(keyPath: "position")
		animation.duration = duration
		animation.beginTime = CACurrentMediaTime() + delay
//		animation.keyTimes = [0, 0.5, 1]
		animation.values = [
			NSValue(SCNVector3: object.position),
//			NSValue(SCNVector3: SCNVector3Make(position.x, position.y + 1, position.z)),
			NSValue(SCNVector3: position)]
		animation.fillMode = kCAFillModeForwards
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		
		return animation
	}
	
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
		return 0.8
	}
	
	func length() -> CGFloat {
		let (min, max) = node.boundingBox
		return max.z - min.z
	}
	
	func positionForLiftedObject(object: LiftableObject) -> SCNVector3! {
		let (min, max) = object.boundingBox
		let liftingObjectHeight = max.y - min.y
		let objectY = CGFloat(height() + (liftingObjectHeight * 0.5))
		let characterPosition = node.position
		let liftingPosition = SCNVector3Make(CGFloat(characterPosition.x), objectY, CGFloat(characterPosition.z))
//		print(objectY)
		
		return liftingPosition
	}
	
	func positionForDroppedObject(object: LiftableObject) -> SCNVector3 {
		let (min, max) = object.boundingBox
		let objectRadius = (max.y - min.y) / 2.0
		let objectZ = self.length() + objectRadius + 1
		let offset = node.convertPosition(SCNVector3Make(0, 0, objectZ), toNode: object)
		let droppedPosition = SCNVector3Make(object.position.x + offset.x, objectRadius, object.position.z + offset.z)
//		print(node.position, offset, droppedPosition)
		
		return droppedPosition
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
			let position = float3(node.position)
			node.position = SCNVector3(position + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
			
			if isLifting {
				lifting?.runAction(SCNAction.moveTo(positionForLiftedObject(lifting!), duration: 0))
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
	private func transitionToAction(action: Action) {
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
	
	private func transitionDurationForAction(action: Action) -> CGFloat {
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
		
		if action == .Lift || action == .Drop {
//			animation.speed = 0.2
		} else {
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
