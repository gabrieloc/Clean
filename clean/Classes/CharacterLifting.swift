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
	
	var isLifting : Bool {
		get {
			return lifting != nil
		}
	}

	func liftObject(object:LiftableObject) {
		if lifting != nil || currentAction == .Fall {
			return
		}
		transitionToAction(.Lift)

		let location = positionForLiftedObject(object)
		let delay = SCNAction.waitForDuration(ONE_FRAME * 5)
		let lift = SCNAction.moveTo(location, duration: ONE_FRAME * 5)
		
		let liftAction = SCNAction.sequence([delay, lift])
		liftAction.timingMode = .EaseOut
		
		object.runAction(liftAction) { () -> Void in
			self.lifting = object
			self.transitionToAction(.Idle)
		}
	}
	
	func positionForLiftedObject(object: LiftableObject) -> SCNVector3! {
		let characterPosition = SCNVector3ToFloat3(node.position)
		let liftingPosition = SCNVector3(characterPosition.x, height(), characterPosition.z)
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
		
		let k1r = SCNAction.rotateByX(-5.degreesToRadians, y: 0, z: 0, duration: ONE_FRAME)
		let k1p = SCNAction.moveByX(0, y: 0, z: -0.5, duration: k1r.duration)
		let k1 = SCNAction.group([k1p, k1r])
		
		let k2r = SCNAction.rotateByX(0, y: 0, z: 0, duration: ONE_FRAME * 3)
		let k2p = SCNAction.moveByX(0, y: 0, z: 0.5, duration: k2r.duration)
		let k2 = SCNAction.group([k2p, k2r])
		
		let k3r = SCNAction.rotateByX(20.degreesToRadians, y: 0, z: 0, duration: ONE_FRAME * 2)
		let k3p = SCNAction.moveTo(finalPositionForObject(object, offset: 0.4), duration: k3r.duration)
		let k3 = SCNAction.group([k3p, k3r])
		
		let k4r = SCNAction.rotateByX(5.degreesToRadians, y: 0, z: 0, duration: ONE_FRAME * 2)
		let k4p = SCNAction.moveTo(finalPositionForObject(object, offset: 0.2), duration: k4r.duration)
		let k4 = SCNAction.group([k4p, k4r])
		
		let k5r = SCNAction.rotateByX(-20.degreesToRadians, y: 0, z: 0, duration: ONE_FRAME * 8)
		let k5p = SCNAction.moveTo(finalPositionForObject(object, offset: 0), duration: k5r.duration)
		let k5 = SCNAction.group([k5p, k5r])
		k5.timingMode = .EaseOut
		
		let actions = SCNAction.sequence([k1, k2, k3, k4, k5])
		
		object.runAction(actions) {
			self.lifting = nil
			self.transitionToAction(.Idle)
		}
		transitionToAction(.Drop)
	}
}

