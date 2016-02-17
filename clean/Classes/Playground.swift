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
}
