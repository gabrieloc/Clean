//
//  Lifting.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-31.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

let ONE_FRAME : NSTimeInterval = 0.03

extension Character {
	
	// MARK: Lifting
	
	var isLifting: Bool {
		return lifting != nil
	}

	func liftObject(object:LiftableObject) {
		if lifting != nil || currentAction == .Fall {
			return
		}

		let location = positionForLiftedObject(object)
		let delay = SCNAction.waitForDuration(ONE_FRAME * 5)
		let lift = SCNAction.moveTo(location, duration: ONE_FRAME * 5)
		
		let liftAction = SCNAction.sequence([delay, lift])
		liftAction.timingMode = .EaseOut
		
		object.physicsBody?.affectedByGravity = false
		
		self.interactable = nil
		self.transitionToAction(.Lift) {
			self.lifting = object
			self.transitionToAction(.Idle)
		}
		object.runAction(liftAction)
	}
	
	func positionForLiftedObject(object: LiftableObject) -> SCNVector3! {
		let characterPosition = SCNVector3ToFloat3(node.position)
		let liftingPosition = SCNVector3(characterPosition.x, height() + 0.1, characterPosition.z)
		return liftingPosition
	}

	// MARK: Dropping
	
	func finalPositionForObject(object: LiftableObject, offset: Float) -> SCNVector3 {
		let (min, max) = object.boundingBox
		// TODO: Calculate how far to throw based off angle lifted from (won't always be Z axis)
		let objectZ = self.length() + (Float(max.z - min.z) * 0.5) - offset
		return node.convertPosition(SCNVector3(0.0, 0.0, objectZ), toNode: nil)
	}
	
	func dropObject() {
		if lifting == nil {
			return
		}
		
		let object = lifting!
		object.physicsBody?.affectedByGravity = true
		
		let k1r = SCNAction.rotateByX(CGFloat(Float(-5).degreesToRadians), y: 0, z: 0, duration: ONE_FRAME * 5)
		let k1p = SCNAction.moveByX(0, y: 0, z: -0.5, duration: k1r.duration)
		let k1 = SCNAction.group([k1p, k1r])
		
		let k2r = SCNAction.rotateByX(0, y: 0, z: 0, duration: ONE_FRAME * 3)
		let k2p = SCNAction.moveTo(finalPositionForObject(object, offset: 0), duration: ONE_FRAME * 7)
		let k2 = SCNAction.group([k2p, k2r])
		
		let actions = SCNAction.sequence([k1, k2])//, k3, k4, k5])
		
		transitionToAction(.Drop) {
			self.delegate?.character(self, didFinishInteractingWithObject: object)
			self.lifting = nil
			self.transitionToAction(.Idle)
		}
		object.runAction(actions)
	}
}

