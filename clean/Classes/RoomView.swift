//
//  RoomView.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class RoomView: SCNView {
	var eventsDelegate: KeyboardAndMouseEventsDelegate?
	
	#if os(OSX)
	
	override func keyDown(theEvent: NSEvent) {
		guard let eventsDelegate = eventsDelegate where eventsDelegate.keyDown(self, theEvent: theEvent) else {
			super.keyDown(theEvent)
			return
		}
	}
	
	override func keyUp(theEvent: NSEvent) {
		guard let eventsDelegate = eventsDelegate where eventsDelegate.keyUp(self, theEvent: theEvent) else {
			super.keyUp(theEvent)
			return
		}
	}

	#endif
}
