//
//  CharacterDriving.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

extension Action {
	func identifierForVehicle(isDriving: Bool, entrance: VehicleEntrance) -> String {
		
		var name: String
		
		switch entrance {
		case .Driver:
			name = isDriving ? "enterTruckLeft" : "enterTruckRight"
		case .Passenger:
			name = isDriving ? "enterTruckRight" : "exitTruckRight"
		case .Trunk:
			name = isDriving ? "enterTruckBack" : "exitTruckBack"
		case .None:
			return ""
		}
		
		return "Character.scnassets/driving/\(name).dae"
	}
}

extension Character {
	
	func beginDrivingVehicle(vehicle: Vehicle, entrance: VehicleEntrance) {
		
		if isDriving() || entrance == .None {
			return
		}
		
		vehicle.beginDrivingFromEntrance(entrance)
		self.vehicleEntrance = entrance
		self.driving = vehicle
		
		self.transitionToAction(.EnterVehicle) { () -> Void in
			self.transitionToAction(.Drive)
		}
	}
	
	func endDriving() {

		if !isDriving() {
			return
		}
		
		self.transitionToAction(.Idle)
		driving!.endDrivingFromEntrance(vehicleEntrance)
		driving = nil
		vehicleEntrance = .None
	}

	func isDriving() -> Bool {
		return driving != nil
	}
	
	internal func driveInDirection(directionInfluence: Float, speed: Float, deltaTime: NSTimeInterval) {
		
		var newDirection = previousDirection
		let isReversing = vehicleAcceleration < 0
		let directionMultiplier: Float = isReversing ? 1.0 : -1.0
		
		if speed == 0.0 {
			vehicleAcceleration += Float(deltaTime) * powf(vehicleAcceleration + 0.5, 2.0) * directionMultiplier
			vehicleAcceleration = directionMultiplier > 0 ? min(0.0, vehicleAcceleration) : max(0.0, vehicleAcceleration)
		} else {
			vehicleAcceleration += Float(deltaTime) * -speed * powf(vehicleAcceleration + 0.7, 4.0)
			if isReversing {
				vehicleAcceleration = max(vehicleAcceleration, -0.08)
			} else {
				vehicleAcceleration = min(vehicleAcceleration, 0.2)
			}
			newDirection -= directionInfluence * vehicleAcceleration * 10
			previousDirection = newDirection
		}		
		directionAngle = CGFloat((newDirection * Float(M_PI)) / 180.0)
		let position = node.convertPosition(SCNVector3(0, 0, vehicleAcceleration), toNode: nil)
		node.position = position
		driving!.position = position
	}
}
