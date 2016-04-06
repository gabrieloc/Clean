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

class RoomViewController: ViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, CharacterDelegate {

	var roomView: RoomView {
		return view as! RoomView
	}
	
	var character : Character {
		return roomView.character
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
		
		character.delegate = self
	}
	
	private func liftableObjectSelected(liftable: LiftableObject) {
		self.character.liftObject(liftable)
	}
	
	// MARK: SCNSceneRendererDelegate
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		replacementPosition = nil
		desiredPosition = nil
		maxPenetrationDistance = 0
		
		let scene = roomView.scene!
		let input = controllerDirection()
		let pov = roomView.pointOfView!
		self.character.directionalInputChanged(input, pov: pov.presentationNode, time: time, scene: scene)

		roomView.cameraNode.runAction(SCNAction.moveTo(character.node.position, duration: 0.5))
		
		roomView.update2DOverlay()
	}
	
	func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
		if let position = desiredPosition {
			character.jumpToPosition(position)
		} else if let position = replacementPosition {
			character.node.position = position
		}
	}

	// MARK: SCNPhysicsContactDelegate
	
	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.characterNode(other, hitWall: matching, withContact: contact)
		}
		contact.match(category: BitmaskLiftable) { (matching, _) in
//			if self.character.isFacingLiftableObject(self.roomView.scene!) == true {
				let liftableObject = matching as! LiftableObject
				self.roomView.presentControlsForLiftableObject(liftableObject)
//			}
			// TODO: make triggered by button
//			self.liftableObjectSelected(matching as! LiftableObject)
		}
		contact.match(category: BitmaskDrivable) { (matching, _) in
			let vehicle = Vehicle.vehicleFromCollisionNode(matching)
			let entrance = vehicle.entranceFromContactPoint(contact.contactPoint)
			self.character.beginDrivingVehicle(vehicle, entrance: entrance)
		}
	}
	
	func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.characterNode(other, hitWall: matching, withContact: contact)
		}
	}
	
	private var maxPenetrationDistance = CGFloat(0.0)
	private var replacementPosition: SCNVector3?
	private var desiredPosition: SCNVector3?
	private let minimumJumpableHeight: CGFloat = 0.1
	private let maximumJumpableHeight: CGFloat = 0.5
	
	private func characterNode(characterNode: SCNNode, hitWall wall: SCNNode, withContact contact:SCNPhysicsContact) {
		if characterNode.parentNode != character.node {
			return
		}
		
		if maxPenetrationDistance > contact.penetrationDistance {
			return
		}
		
		maxPenetrationDistance = contact.penetrationDistance
		
		let elevation = CGFloat(contact.contactPoint.y) - CGFloat(character.node.position.y)
		let isFacingWall = character.isFacingWall(roomView.scene!)
		if isFacingWall && elevation > minimumJumpableHeight && elevation < maximumJumpableHeight {
			desiredPosition = contact.contactPoint
		} else {
			var positionOffset = float3(contact.contactNormal) * Float(contact.penetrationDistance)
			positionOffset.y = 0
			var characterPosition = float3(character.node.position)
			characterPosition += positionOffset
			replacementPosition = SCNVector3(characterPosition)
		}
	}
	
	// MARK: CharacterDelegate
	
	private var lastZoomLevel = Double()
	func character(character: Character, willTransitionToAction: Action) {

		var zoomLevel: Double
		
		if willTransitionToAction == .Fall || willTransitionToAction == .Lift {
			zoomLevel = 2.5
		}
		else if willTransitionToAction == .Drive {
			zoomLevel = 3.0
		}
		else {
			zoomLevel = 2.0
		}
		
		if lastZoomLevel != zoomLevel {
			SCNTransaction.begin()
			SCNTransaction.setAnimationDuration(1.0)
			roomView.cameraNode.camera!.orthographicScale = zoomLevel
			SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
			SCNTransaction.commit()
		}
	}
}
