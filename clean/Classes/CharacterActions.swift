//
//  CharacterActions.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-06.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import Foundation

enum Action: String {
	case Idle = "idle"
	case Walk = "walk"
	case Lift = "lift"
	case Drop = "drop"
	case Jump = "jump"
	case Fall = "fall"
	
	func identifier() -> String {
		return identifier(false)
	}
	
	func identifier(isLifting: Bool) -> String {
		
		var name: String
		
		if isLifting && self != .Lift && self != .Drop {
			name = "\(self.rawValue)-lifting"
		} else {
			name = self.rawValue
		}
		
		return "Character.scnassets/actions/\(name).dae"
	}
	
	enum ActionDuration: NSTimeInterval {
		case VeryFast = 0.01
		case Fast = 0.1
		case Slow = 0.2
	}
	
	func transitionDurationFromAction(fromAction: Action, isLifting: Bool) -> CGFloat {
		
		if self == .Idle && (isLifting || fromAction == .Jump) {
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
