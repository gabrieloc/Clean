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
	
	internal func driveInDirection(direction: float3, deltaTime: NSTimeInterval) {
		
		let acceleration: Float = 0.15
		var newDirection = float3()
		
		if direction.x == 0 && direction.y == 0 {
			// TODO: decelerate
			vehicleAcceleration *= Float(deltaTime) * 0.9
			previousDirection = previousDirection * vehicleAcceleration
			newDirection = previousDirection
			vehicleAcceleration = max(vehicleAcceleration, 0.0)
		}
		else {
			vehicleAcceleration += Float(deltaTime) * acceleration
			vehicleAcceleration = min(vehicleAcceleration, 0.25)
			previousDirection = direction
			newDirection = direction * vehicleAcceleration
			
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
			print(directionAngle)
		}
		
		let position = SCNVector3(float3(node.position) + newDirection)
		node.position = position
		driving!.position = position
		
	}
}
