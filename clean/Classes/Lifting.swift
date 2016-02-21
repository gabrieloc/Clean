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
		if lifting != nil {
			return
		}
		
		let location = positionForLiftedObject(object)
		let delay = SCNAction.waitForDuration(ONE_FRAME)
		let lift = SCNAction.moveTo(location, duration: ONE_FRAME * 2)
		
		let liftAction = SCNAction.sequence([delay, lift])
		liftAction.timingMode = .EaseOut
		object.runAction(liftAction) { () -> Void in
			self.lifting = object
			self.transitionToAction(.Idle)
		}
		transitionToAction(.Lift)
	}
	
	func positionForLiftedObject(object: LiftableObject) -> SCNVector3! {
		let (min, max) = object.boundingBox
		let objectRadius =  Float(max.y - min.y) * 0.5
		let objectY = height() + objectRadius
		let characterPosition = SCNVector3ToFloat3(node.position)
		let liftingPosition = SCNVector3(characterPosition.x, objectY, characterPosition.z)
		
		return liftingPosition
	}

	
	// MARK: Dropping
	
	func relativeXRotate(rotation: SCNVector4, xAngle: CGFloat) -> SCNVector4 {
		return SCNVector4(xAngle, 0.0, 0.0, CGFloat(M_PI) * 2.0)
	}
	
	func finalPositionForObject(object: LiftableObject, offset: Float) -> SCNVector3 {
		let (min, max) = object.boundingBox
		let objectRadius = Float(max.y - min.y) * 0.5
		let objectZ = self.length() + objectRadius - offset
		return node.convertPosition(SCNVector3(0.0, objectRadius, objectZ), toNode: nil)
	}
	
	func dropObject() {
		if lifting == nil {
			return
		}
		
		let object = lifting!
//		let (min, max) = object.boundingBox
//		let objectRadius = (max.y - min.y) * 0.5
//		let originalPivot = object.pivot
//		object.pivot = SCNMatrix4MakeTranslation(0, -objectRadius, 0)
		
		let k1r = SCNAction.rotateToAxisAngle(relativeXRotate(object.rotation, xAngle: -5), duration: ONE_FRAME)
		let k1p = SCNAction.moveByX(0, y: 0, z: -0.1, duration: ONE_FRAME)
		let k1 = SCNAction.group([k1p, k1r])
		
		let k2r = SCNAction.rotateToAxisAngle(relativeXRotate(object.rotation, xAngle: 0), duration: ONE_FRAME * 2)
		let k2p = SCNAction.moveByX(0, y: 0, z: 0.1, duration: ONE_FRAME * 2)
		let k2 = SCNAction.group([k2p, k2r])
		
		let k3r = SCNAction.rotateToAxisAngle(relativeXRotate(object.rotation, xAngle: 20), duration: ONE_FRAME * 4)
		let k3p = SCNAction.moveTo(finalPositionForObject(object, offset: 0.2), duration: ONE_FRAME * 4)
		let k3 = SCNAction.group([k3p, k3r])
		
		let k4r = SCNAction.rotateToAxisAngle(relativeXRotate(object.rotation, xAngle: 30), duration: ONE_FRAME * 3)
		let k4p = SCNAction.moveTo(finalPositionForObject(object, offset: 0.1), duration: ONE_FRAME * 3)
		let k4 = SCNAction.group([k4p, k4r])
		
		let k5r = SCNAction.rotateToAxisAngle(relativeXRotate(object.rotation, xAngle: 0), duration: ONE_FRAME * 5)
		let k5p = SCNAction.moveTo(finalPositionForObject(object, offset: 0), duration: ONE_FRAME * 5)
		let k5 = SCNAction.group([k5p, k5r])
		k5.timingMode = .EaseOut
		
		let actions = SCNAction.sequence([k1, k2, k3, k4, k5])
		
		object.runAction(actions) {
//			object.pivot = originalPivot
			self.lifting = nil
			self.transitionToAction(.Idle)
		}
		transitionToAction(.Drop)
	}
}

