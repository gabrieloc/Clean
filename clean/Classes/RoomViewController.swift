//
//  RoomViewController.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2015-12-26.
//  Copyright © 2015 Gabrieloc. All rights reserved.
//


import SceneKit
import GameController

let BitmaskCollision = 1 << 2
let BitmaskLiftable  = 1 << 3
let BitmaskDrivable = 1 << 4

#if os(iOS) || os(tvOS)
	import UIKit
	typealias ViewController = UIViewController
#elseif os(OSX)
	import AppKit
	typealias ViewController = NSViewController
#endif

class RoomViewController: ViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

	var roomView: RoomView {
		return view as! RoomView
	}
	
	// Controls
	internal var controllerDPad: GCControllerDirectionPad?
	internal var controllerStoredDirection = float2(0.0)
	
	#if os(iOS)
	internal var panningTouch: UITouch?
	#endif
	
	// MARK: Initialization
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		let scene = roomView.scene!
		scene.physicsWorld.contactDelegate = self
		roomView.delegate = self
		setupGameControllers()
	}
	
	// MARK: SCNSceneRendererDelegate
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {	
		let input = controllerDirection()
		roomView.directionalInputChanged(input, time: time)
	}
	
	func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
		roomView.updateControllableWithTime(time)
		
//		else if let position = replacementPosition {
//			character.node.position = position
//		}
	}

	// MARK: SCNPhysicsContactDelegate
	
	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.roomView.updateContactForControllable(other, hitWall: matching, contact: contact)
		}
		contact.match(category: BitmaskLiftable | BitmaskDrivable) { (matching, _) in
			self.roomView.presentControlsForInteractable(matching, contactPoint: contact.contactPoint)
		}
	}
	
	func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.roomView.updateContactForControllable(other, hitWall: matching, contact: contact)
		}
	}
	

}
