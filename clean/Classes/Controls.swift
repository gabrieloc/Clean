//
//  Controls.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import simd
import SceneKit
import GameController

extension RoomViewController {
	
	// MARK: Controller orientation
	
	private static let controllerAcceleration = Float(1.0 / 10.0)
	private static let controllerDirectionLimit = float2(1.0)
	
	internal func controllerDirection() -> float2 {
		if let dpad = controllerDPad {
			if dpad.xAxis.value == 0.0 && dpad.yAxis.value == 0.0 {
				controllerStoredDirection = float2(0.0)
			} else {
				let inputValue = float2(dpad.xAxis.value, -dpad.yAxis.value * RoomViewController.controllerAcceleration)
				print(inputValue)
				controllerStoredDirection = clamp(controllerStoredDirection + inputValue,
					min: -RoomViewController.controllerDirectionLimit,
					max: RoomViewController.controllerDirectionLimit)
			}
		}
		return controllerStoredDirection
	}
	
	// MARK: Events
	
	#if os(iOS)
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if panningTouch == nil {
			controllerStoredDirection = float2(0.0)
			panningTouch = touches.first
		}
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let touch = panningTouch {
			let newLocation = float2(touch.locationInView(view))
			let oldLocation = float2(touch.previousLocationInView(view))
			let displacement = newLocation - oldLocation
			controllerStoredDirection = clamp(mix(controllerStoredDirection, displacement, t: RoomViewController.controllerAcceleration), min: -RoomViewController.controllerDirectionLimit, max: RoomViewController.controllerDirectionLimit)
		}
	}
	
	func commonTouchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let touch = panningTouch {
			if touches.contains(touch) {
				panningTouch = nil
				controllerStoredDirection = float2(0.0)
			}
		}
	}
	
	override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
		commonTouchesEnded(touches!, withEvent: event)
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		commonTouchesEnded(touches, withEvent: event)
	}
	
	#endif
}
