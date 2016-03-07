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
		
		let objects:[Prop] = [.CKComb, .CKCream, .CKFoam, .CKMouthwash, .CKRazor, .CKSoapDish, .CKSoap, .CKToothbrush, .CKToothpaste, .CKWax]
		for (index, prop) in objects.enumerate() {
			let object = LiftableObject(propName: prop)
			let x = (sin(Float(index % 4) * Float(M_PI_2)) * Float(index))// * 5.0
			let z = (cos(Float(index % 4) * Float(M_PI_2)) * Float(index))// * 5.0
			object.position = SCNVector3(x, 0, z)
			rootNode.addChildNode(object)
		}
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
