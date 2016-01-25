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
	var lifting: SCNNode? {
		didSet {
			if lifting == oldValue {
				return
			}
			
//			dropZoneVisible = isLifting
			
			let desiredLiftingPosition = isLifting ? positionForLiftedObject(lifting!) : positionForDroppedObject(oldValue!)
			let liftingObject = isLifting ? lifting! : oldValue!
			
			SCNTransaction.begin()
			SCNTransaction.setAnimationDuration(0.3)
			SCNTransaction.setCompletionBlock({
				self.transitionToAction(.Idle)

				liftingObject.removeAnimationForKey("lift")
				liftingObject.position = desiredLiftingPosition
			})
			
			var liftingObjectAnimation: CAAnimation
			if isLifting {
				liftingOriginalPosition = lifting!.position
				transitionToAction(.Lift)
				liftingObjectAnimation = animationForLiftedObject(liftingObject, position:desiredLiftingPosition, duration:0.2, delay:0.1)
			} else {
				transitionToAction(.Drop)
				liftingObjectAnimation = animationForLiftedObject(liftingObject, position:desiredLiftingPosition, duration:0.4, delay:0)
			}
			liftingObject.addAnimation(liftingObjectAnimation, forKey: "lift")
			
			SCNTransaction.commit()
		}
	}

	var isLifting : Bool {
		get {
			return lifting != nil
		}
	}
	
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
		animation.removedOnCompletion = false
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		
		return animation
//		lifting?.addAnimation(animation, forKey: "lift")
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
				node.runAction(SCNAction.rotateToX(0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.2, shortestUnitArc: true))
			}
		}
	}
	
	func height() -> CGFloat {
		let (min, max) = node.boundingBox
		return max.y - min.y
	}
	
	func positionForLiftedObject(object:SCNNode) -> SCNVector3! {
		let (min, max) = lifting!.boundingBox
		let liftingObjectHeight = max.y - min.y
		let objectY = self.height() + liftingObjectHeight
		
		let characterPosition = node.position
		let liftingPosition = SCNVector3Make(CGFloat(characterPosition.x), objectY, CGFloat(characterPosition.z))

		return liftingPosition
	}
	
	func positionForDroppedObject(object:SCNNode) -> SCNVector3 {
		//TODO calculate based off lifted object dimensions
		let offset = node.convertPosition(SCNVector3Make(0, 0, 1.65), toNode: object)
		let droppedPosition = SCNVector3Make(object.position.x + offset.x, 1, object.position.z + offset.z)
		
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
				lifting!.runAction(SCNAction.moveTo(positionForLiftedObject(lifting!), duration: 0))
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
			print(key)
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
