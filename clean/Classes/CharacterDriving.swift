//
//  CharacterDriving.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

extension Character {
	
	func beginDriving(vehicle: Vehicle) {
		
		// TODO: calculate which side to enter from
		
		driving = vehicle
		
		transitionToAction(.Drive)
	}
	
	func endDriving() {
		
		// TODO: calculate which side to exit from
		
		transitionToAction(.Idle)
	}
}
