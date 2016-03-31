//
//  CharacterDriving.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

extension Action {
	func drivingIdentifier(isDriving: Bool, entrance: VehicleEntrance) -> String {
		
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
		
		driving = vehicle
		vehicleEntrance = entrance
		
		transitionToAction(.Drive)
	}
	
	func endDriving() {

		if !isDriving() {
			return
		}
		
		driving = nil
		vehicleEntrance = .None
		
		transitionToAction(.Idle)
	}

	func isDriving() -> Bool {
		return driving != nil
	}
}
