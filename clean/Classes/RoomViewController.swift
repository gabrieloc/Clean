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
	}
	
	// MARK: Character Movement
	
	private func characterDirection() -> float3 {
		let controllerDirection = self.controllerDirection()
		var direction = float3(controllerDirection.x, 0.0, controllerDirection.y)
		if let pov = roomView.pointOfView {
			let p1 = pov.presentationNode.convertPosition(SCNVector3(direction), toNode: nil)
			let p0 = pov.presentationNode.convertPosition(SCNVector3Zero, toNode: nil)
			direction = float3(Float(p1.x - p0.x), 0.0, Float(p1.z - p0.z))
			
			if direction.x != 0.0 || direction.z != 0.0 {
				direction = normalize(direction)
			}
		}
		
		return direction
	}
	
	// MARK: SCNSceneRendererDelegate
	
	func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
		replacementPosition = nil
		desiredPosition = nil
		maxPenetrationDistance = 0
		
		let scene = roomView.scene!
		let direction = characterDirection()
		character.walkInDirection(direction, time: time, scene: scene)

		roomView.cameraNode.position = character.node.position
	}
	
	func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
		if let position = desiredPosition {
			// TODO: have character jump to this point 
			character.node.position = position
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
			let lifting = matching as! LiftableObject
			self.character.liftObject(lifting)
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
		
		let elevation = contact.contactPoint.y - CGFloat(character.node.position.y)
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
}
