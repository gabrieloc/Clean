//
//  LiftableObject.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-15.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class LiftableObject {

	init() {
		let geometry = SCNSphere(radius: 1)
		geometry.firstMaterial = SCNMaterial()
		geometry.firstMaterial?.diffuse.contents = NSColor.redColor()
		node.geometry = geometry
		
//		let collisionNode = SCNNode()
//		collisionNode.name = "collision"
//		collisionNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
//		collisionNode.physicsBody!.categoryBitMask = BitmaskCollision
//		collisionNode.physicsBody!.physicsShape = SCNPhysicsShape(node: node, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
//		collisionNode.position = SCNVector3(0.0, 1.0, 0.0)
//		node.addChildNode(collisionNode)
		
		node.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
		node.physicsBody!.categoryBitMask = BitmaskLiftable
	}
	
	let node = SCNNode()
}
