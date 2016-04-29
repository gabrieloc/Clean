//
//  RoomView.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit
import SpriteKit

class RoomView : SCNView, CharacterDelegate {

	private var character : Character = Character()
	private var cameraNode : SCNNode {
		return scene!.rootNode.childNodeWithName("PlayerCamera", recursively: true)!
	}
	
	private let overlayNode = SKNode()
	
	override init(frame: CGRect) {
		super.init(frame:frame)
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	func commonInit() {
		
		self.character.delegate = self
		self.scene = Playground.init(character: character)
		
		playing = true
		loops = true
		showsStatistics = true
	}
	
	func directionalInputChanged(input: float2, time: NSTimeInterval) {
		
		replacementPosition = nil
		desiredPosition = nil
		maxPenetrationDistance = 0.0
		
		let pov = pointOfView!.presentationNode
		character.directionalInputChanged(input, pov: pov.presentationNode, time: time, scene: scene!)

		
		cameraNode.runAction(SCNAction.moveTo(character.node.position, duration: 0.5))
		update2DOverlay()
	}
	
	func actionInputChanged(input: ActionInput, selected: Bool) {
		character.actionInput(input, selected: selected)
	}
	
	#if os(iOS) || os(tvOS)
	
	override func awakeFromNib() {
		super.awakeFromNib()
		setup2DOverlay()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layout2DOverlay()
	}
	
	#elseif os(OSX)
	
	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		setup2DOverlay()
	}
	
	override func setFrameSize(newSize: NSSize) {
		super.setFrameSize(newSize)
		layout2DOverlay()
	}
	
	#endif

	
	#if os(OSX)
	var eventsDelegate: KeyboardAndMouseEventsDelegate?
	
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
	
	func setup2DOverlay() {

		let skscene = SKScene(size: bounds.size)
		skscene.scaleMode = .ResizeFill
		
		skscene.addChild(overlayNode)
		
		overlaySKScene = skscene
	}
	
	func layout2DOverlay() {
		overlayNode.position = CGPointMake(0.0, 0.0)
	}
	
	func update2DOverlay() {
		
		controllableNodes.forEach { (object, node) -> () in
			node.position = positionForNode(object)
		}
	}
	
	// MARK: Controls
	
	private var controllableNodes = [SCNNode: SKNode]()
	
	func presentControlsForInteractable(interactable: SCNNode, contactPoint: SCNVector3) {

		if controllableNodes[interactable] != nil {
			// Update control node position
		} else {
			let controlNode = SKShapeNode(circleOfRadius: 20)
			controlNode.position = positionForNode(interactable)
			overlayNode.addChild(controlNode)
			
			controllableNodes.forEach({ (object: SCNNode, controls: SKNode) in
				controls.removeFromParent()
				controllableNodes.removeValueForKey(object)
			})
			controllableNodes[interactable] = controlNode
		}
		
		character.interactable = interactable
		
		if let vehicle = interactable as? Vehicle {
			character.storedEntrance = vehicle.entranceFromContactPoint(contactPoint)
		}
	}
	
	func dismissControlsForNode(node: SCNNode) {
		if let controlNode = controllableNodes[node] {
			controlNode.removeFromParent()
			controllableNodes[node] = nil
		}
	}
	
	internal func positionForNode(node: SCNNode) -> CGPoint {
		let projectedPosition = projectPoint(node.presentationNode.position)
		return CGPoint(x: projectedPosition.x, y: projectedPosition.y)
	}
	
	// MARK: Physics
	
	private var replacementPosition: SCNVector3?
	private var desiredPosition: SCNVector3?
	private var maxPenetrationDistance = CGFloat(0.1)
	private let minimumJumpableHeight: CGFloat = 0.01
	private let maximumJumpableHeight: CGFloat = 0.1
	
	func updateControllableWithTime(time: NSTimeInterval) {
		
		// TODO: update altitude of vehicles, other players
		
		if let position = desiredPosition {
			character.jumpToPosition(position)
		}
	}
	
	func updateContactForControllable(controllable: SCNNode, hitWall: SCNNode, contact: SCNPhysicsContact) {
		
		if character.node.parentNode != character.node {
			return
		}
		
		if maxPenetrationDistance > contact.penetrationDistance {
			return
		}
		
		maxPenetrationDistance = contact.penetrationDistance
		
		let elevation = CGFloat(contact.contactPoint.y) - CGFloat(character.node.position.y)
		let isFacingWall = character.isFacingWall(scene!)
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
			cameraNode.camera!.orthographicScale = zoomLevel
			SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
			SCNTransaction.commit()
		}
	}
	
	func character(character: Character, didFinishInteractingWithObject: AnyObject) {
		let node = didFinishInteractingWithObject as! SCNNode
		dismissControlsForNode(node)
	}
}
