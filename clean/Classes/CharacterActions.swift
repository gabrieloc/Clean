//
//  CharacterActions.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-06.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

enum Action: String {
	case Idle = "idle"
	case Walk = "walk"
	case Lift = "lift"
	case Drop = "drop"
	case Jump = "jump"
	case Fall = "fall"
	
	case EnterVehicle = "enterVehicle"
	case ExitVehicle = "exitVehicle"
	case Drive = "drive"
	
	func identifier() -> String {
		return identifier(false)
	}
	
	func identifier(isLifting: Bool) -> String {
		
		var name: String
		
		if isLifting && self != .Lift && self != .Drop {
			name = "\(self.rawValue)-lifting"
		}
		else {
			name = self.rawValue
		}
		
		return "Character.scnassets/actions/\(name).dae"
	}
	
	func identiferForNewVehicleAction(action: Action, entrance: VehicleEntrance) -> String {
		
		let name = "\(action.rawValue)\(entrance.rawValue)"
		return "Character.scnassets/actions/\(name).dae"
	}
	
	func transitionDurationFromAction(fromAction: Action, isLifting: Bool) -> CGFloat {
		if self == .Drive || fromAction == .Drive {
			return 0.0
		} else if self == .Idle && fromAction == .Jump {
			return 0.01
		}
		else if self == .Lift || self == .Drop || self == .Jump {
			return 0.1
		}
		else {
			return 0.2
		}
	}
}
