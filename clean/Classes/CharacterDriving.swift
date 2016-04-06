//
//  CharacterDriving.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

extension Character {
	
	func beginDrivingVehicle(vehicle: Vehicle, entrance: VehicleEntrance) {
		
		if isDriving || entrance == .None {
			return
		}
		
		vehicle.beginDrivingFromEntrance(entrance)
		self.driving = vehicle
		self.vehicleEntrance = entrance		
		self.transitionToAction(.EnterVehicle) { () -> Void in
			self.transitionToAction(.Drive)
		}
	}
	
	func endDriving() {

		if !isDriving {
			return
		}
		
		// TODO: exit based off side closest to camera
		vehicleEntrance = .Driver
		self.driving!.endDrivingFromEntrance(vehicleEntrance)
		self.transitionToAction(.ExitVehicle) { () -> Void in
			self.driving = nil
			self.vehicleEntrance = .None
			
			self.directionAngle += SCNFloat(M_PI_2)
			self.updateDirectionAnimated(false)
			
			self.transitionToAction(.Idle)
		}
	}

	var isDriving: Bool {
		get {
			return driving != nil
		}
	}
	
	internal func driveInDirection(directionInfluence: Float, speed: Float, deltaTime: NSTimeInterval) {
		
		var newDirection = previousDirection
		let isReversing = vehicleAcceleration < 0
		let directionMultiplier: Float = isReversing ? 1.0 : -1.0
		
		if speed == 0.0 || self.currentAction != .Drive {
			vehicleAcceleration += Float(deltaTime) * powf(vehicleAcceleration + 0.5, 2.0) * directionMultiplier
			vehicleAcceleration = directionMultiplier > 0 ? min(0.0, vehicleAcceleration) : max(0.0, vehicleAcceleration)
		} else {
			vehicleAcceleration += Float(deltaTime) * -speed * powf(vehicleAcceleration + 0.7, 4.0)
			if isReversing {
				vehicleAcceleration = max(vehicleAcceleration, -0.05)
			} else {
				vehicleAcceleration = min(vehicleAcceleration, 0.15)
			}
		}
		newDirection -= directionInfluence * vehicleAcceleration * 10.0
		previousDirection = newDirection
		
		directionAngle = CGFloat((newDirection * Float(M_PI)) / 180.0)
		updateDirectionAnimated(false)
		
		let vehicleOffset = float3(0, 0, vehicleAcceleration)
		let vehiclePosition = driving!.convertPosition(SCNVector3(vehicleOffset), toNode: nil)
		let characterOffset = float3(1.4, 0.0, 0.5)
		let characterPosition = driving!.convertPosition(SCNVector3(vehicleOffset + characterOffset), toNode: nil)
		node.position = characterPosition
		driving!.position = vehiclePosition	
	}
}
