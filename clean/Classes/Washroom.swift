//
//  Washroom.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-02-14.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class Washroom : SCNScene {
	
	private var character: Character!
	private var startingNode: SCNNode!
	var cameraNode: SCNNode!
	
	init(character: Character) {
		super.init()
		
		let scene = SCNScene.init(named: "game.scnassets/scenes/playground.scn")!
		self.startingNode = scene.rootNode.childNodeWithName("startingPoint", recursively: true)!
		rootNode.addChildNode(scene.rootNode)
		
		self.character = character
		rootNode.addChildNode(character.node)
		character.node.position = startingNode.position
		
		let geometry = scene.rootNode.childNodeWithName("roomGeometry", recursively: false)!
		geometry.enumerateChildNodesUsingBlock { (node, _) in
			self.setupCollisionNode(node)
		}
		
		seedPropGeometry(200)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func setupCollisionNode(node : SCNNode) {
		if node.geometry != nil {
			// Collision meshes must use a concave shape for intersection correctness.
			node.physicsBody = SCNPhysicsBody.staticBody()
			node.physicsBody!.categoryBitMask = BitmaskCollision
			node.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options: nil)
		}
		
		for childNode in node.childNodes {
			setupCollisionNode(childNode)
		}
	}
	
	func seedPropGeometry(count: NSInteger) {
		for index in 0...count {
			let object = LiftableObject.randomObjectWithHeight(CGFloat(arc4random_uniform(UInt32(index))) * 0.1)
			object.position = SCNVector3Make(
				CGFloat(arc4random_uniform(UInt32(index))),
				60,
				CGFloat(arc4random_uniform(UInt32(index))))
			self.rootNode.addChildNode(object)
		}
	}
}
