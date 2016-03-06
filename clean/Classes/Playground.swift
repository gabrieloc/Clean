//
//  Playground.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-02-13.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class Playground : SCNScene {

	private var character: Character!
	var cameraNode: SCNNode!

	init(character: Character) {
		super.init()
		
		let scene = SCNScene.init(named: "game.scnassets/scenes/playground.scn")!
		rootNode.addChildNode(scene.rootNode)
		
		self.character = character
		rootNode.addChildNode(character.node)
		character.node.position = SCNVector3Make(0, 5.0, 0);

		scene.rootNode.enumerateChildNodesUsingBlock { (node, _) in
			if node != character.node {
				self.setupCollisionNode(node)
			}
		}
		
//		seedPropGeometry(10)
		
		let comb = LiftableObject(propName: .CKComb)
		comb.position = SCNVector3Make(0, 0, 5)
		rootNode.addChildNode(comb)
		
		let cream = LiftableObject(propName: .CKCream)
		cream.position = SCNVector3Make(5, 0, 5)
		rootNode.addChildNode(cream)
		
		let foam = LiftableObject(propName: .CKFoam)
		foam.position = SCNVector3Make(5, 0, 10)
		rootNode.addChildNode(foam)
	}
	
	func setupCollisionNode(node : SCNNode) {
		if node.physicsBody != nil {
			node.physicsBody!.categoryBitMask = BitmaskCollision
		}
		
		for childNode in node.childNodes {
			setupCollisionNode(childNode)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func seedPropGeometry(count: NSInteger) {
		for index in 0...count {
			let object = LiftableObject.randomObjectWithHeight(CGFloat(arc4random_uniform(UInt32(index))) * 0.1)
			object.position = SCNVector3(
				CGFloat(arc4random_uniform(UInt32(index))),
				10.0,
				CGFloat(arc4random_uniform(UInt32(index))))
			self.rootNode.addChildNode(object)
		}
	}
}
