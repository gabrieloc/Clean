//
//  RoomViewController.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2015-12-26.
//  Copyright © 2015 Gabrieloc. All rights reserved.
//

import UIKit
import SceneKit
import GameController

// Collision bit masks
let BitmaskCollision        = 1 << 2
let BitmaskWater            = 1 << 3

#if os(iOS) || os(tvOS)
	typealias ViewController = UIViewController
#elseif os(OSX)
	typealias ViewController = NSViewController
#endif

class RoomViewController: ViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
	
	var roomView: RoomView {
		return view as! RoomView
	}
	
	private let character = Character()
	
	// Camera
	private var currentGround: SCNNode!
	private var mainGround: SCNNode!
	private var groundToCameraPosition = [SCNNode: SCNVector3]()
	
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
	
		let scene = SCNScene(named: "game.scnassets/room.scn")!
		
		self.roomView.scene = scene
		self.roomView.playing = true
		self.roomView.loops = true
		
		setupCamera()
		setupSounds()
		
		scene.rootNode.addChildNode(character.node)
		
		let startPosition = scene.rootNode.childNodeWithName("startingPoint", recursively: true)!
		character.node.transform = startPosition.transform
		
		// Collisions
		var collisionNodes = [SCNNode]()
		scene.rootNode.enumerateChildNodesUsingBlock { (node, _) in
			switch node.name {
			case let .Some(s) where s.rangeOfString("collision") != nil:
				collisionNodes.append(node)
			default:
				break;
			}
		}
		
		for node in collisionNodes {
			node.hidden = false
			setupCollisionNode(node)
		}
		
		scene.physicsWorld.contactDelegate = self
		roomView.delegate = self
	}
	
	private func setupCollisionNode(node: SCNNode) {
		if node.geometry != nil {
			node.physicsBody = SCNPhysicsBody.staticBody()
			node.physicsBody!.categoryBitMask = BitmaskCollision
			node.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeBoundingBox])
		}
	}
	
	// MARK: Camera
	
	func setupCamera() {
//		let panGesture = UIPanGestureRecognizer(target: self, action: "didPan:")
//		sceneView.addGestureRecognizer(panGesture)
	}
	
	func updateCameraWithCurrentGround(node: SCNNode) {
		if currentGround == nil {
			currentGround = node
			return
		}
		
		if node != currentGround {
			currentGround = node
//			if var position = groundToCameraPosition[node] {
//				if node = mainGround && character.node.position.x < 2.5 {
//					position = SCNVector3
//				}
				//TODO
//			}
		}
	}
	
	func setupSounds() {
		
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
		let scene = roomView.scene!
		let direction = characterDirection()
		
		let groundNode = character.walkInDirection(direction, time: time, scene: scene)
		if let groundNode = groundNode {
			updateCameraWithCurrentGround(groundNode)
		}
	}
	
	// MARK: SCNPhysicsContactDelegate
	
	func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.characterNode(other, hitWall: matching, withContact: contact)
		}
	}
	
	func physicsWorld(world: SCNPhysicsWorld, didUpdateContact contact: SCNPhysicsContact) {
		contact.match(category: BitmaskCollision) { (matching, other) in
			self.characterNode(other, hitWall: matching, withContact: contact)
		}
	}
	
	
	private var maxPenetrationDistance = CGFloat(0.0)
	private var replacementPosition: SCNVector3?
	
	private func characterNode(characterNode: SCNNode, hitWall wall: SCNNode, withContact contact:SCNPhysicsContact) {
		if characterNode.parentNode != character.node {
			return
		}
		
		if maxPenetrationDistance > contact.penetrationDistance {
			return
		}
		
		maxPenetrationDistance = contact.penetrationDistance
		
		var characterPosition = float3(character.node.position)
		var positionOffset = float3(contact.contactNormal) * Float(contact.penetrationDistance)
		positionOffset.y = 0
		characterPosition += positionOffset
		
		replacementPosition = SCNVector3(characterPosition)
	}
}
