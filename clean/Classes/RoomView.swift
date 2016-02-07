//
//  RoomView.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class RoomView : SCNView {

	var character : Character = Character()
	var cameraNode : SCNNode {
		return scene!.rootNode.childNodeWithName("PlayerCamera", recursively: true)!
	}
	
	override init(frame: CGRect) {
		super.init(frame:frame)

		scene = SCNScene(named: "game.scnassets/room/room.scn")!
		
		let startingPosition = scene!.rootNode.childNodeWithName("startingPoint", recursively: true)!.position
		character.node.position = startingPosition
		scene!.rootNode.addChildNode(character.node)
		
		playing = true
		loops = true
		showsStatistics = true
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

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
