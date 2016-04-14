//
//  RoomView.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit
import SpriteKit

class RoomView : SCNView {

	var character : Character = Character()
	var cameraNode : SCNNode {
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
		self.scene = Playground.init(character: character)
		
		playing = true
		loops = true
		showsStatistics = true
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
	
	func presentControlsForNode(node: SCNNode) {

		if controllableNodes[node] != nil {
			// Update control node position
		} else {
			let controlNode = SKShapeNode(circleOfRadius: 20)
			controlNode.position = positionForNode(node)
			overlayNode.addChild(controlNode)
			
			controllableNodes.forEach({ (object: SCNNode, controls: SKNode) in
				controls.removeFromParent()
				controllableNodes.removeValueForKey(object)
			})
			controllableNodes[node] = controlNode
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
}
