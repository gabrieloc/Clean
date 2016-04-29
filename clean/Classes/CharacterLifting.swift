//
//  Lifting.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-31.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

func secondsFromFrames(frames: NSInteger) -> NSTimeInterval {
	let frameDuration = 1.0 / 60.0
	return frameDuration * Double(frames)
}

extension Character {
	
	// MARK: Lifting
	
	var isLifting: Bool {
		return lifting != nil
	}

	func liftObject(object: LiftableObject) {
		if isLifting || currentAction == .Fall {
			return
		}

		let transitionDuration = NSTimeInterval(Action.Lift.transitionDurationFromAction(currentAction, isLifting: false))
		
		let delay = SCNAction.waitForDuration(transitionDuration)
		let lift = SCNAction.moveTo(positionForLiftedObject(object), duration: secondsFromFrames(15))
		
		let liftAction = SCNAction.sequence([delay, lift])
		liftAction.timingMode = .EaseOut
		
		object.lifted = true
		
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

	func dropInputSelected(selected: Bool) {
		
		if selected {
			dropForceTimer = NSTimer.init(timeInterval: 1.0 / 60.0, target: self, selector: nil, userInfo: nil, repeats: true)
		}
		else {
			let time = NSDate().timeIntervalSinceDate(dropForceTimer.fireDate)
			let dropForce = max(4.0, Float(time * 10.0))
			print(dropForce)
			dropObject(lifting!, force: dropForce)
			dropForceTimer.invalidate()
		}
	}
	
	func dropObject(object: LiftableObject!, force: Float) {
		
		object.lifted = false
		let delay = SCNAction.waitForDuration(0.2)
		object.runAction(delay) { 
			let direction = self.node.convertPosition(SCNVector3(0.0, 0.0, force), toNode: nil)
			object.physicsBody?.applyForce(direction, impulse: true)
		}
		
		transitionToAction(.Drop) {
			self.delegate?.character(self, didFinishInteractingWithObject: object)
			self.lifting = nil
			self.transitionToAction(.Idle)
		}
	}
}

