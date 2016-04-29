//
//  LiftableObject.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-15.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class LiftableObject : SCNNode {
	
	class func randomObjectWithHeight(height: CGFloat) -> LiftableObject {
		
		let object = LiftableObject()
		
		var geometry: SCNGeometry
		switch arc4random() % 4 {
		case 0:
			geometry = SCNSphere(radius: height)
		case 1:
			geometry = SCNBox(width: height, height: height, length: height, chamferRadius: 0)
		case 2:
			geometry = SCNPyramid(width: height, height: height, length: height)
		case 3:
			geometry = SCNCylinder(radius: height, height: height)
		default:
			geometry = SCNCone(topRadius: height, bottomRadius: height, height: height)
		}
		
		geometry.firstMaterial = SCNMaterial()
		geometry.firstMaterial?.diffuse.contents = blueColor()
		object.geometry = geometry
		object.updatePhysicsBody()
		
		return object
	}
	
	var lifted: Bool = false {
		didSet {
			updatePhysicsBody()
		}
	}
	
	func updatePhysicsBody() {
		if lifted {
			self.physicsBody?.type = .Kinematic
		}
		else {
			let physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(node: self, options: nil))
			physicsBody.categoryBitMask = BitmaskLiftable
			physicsBody.friction = 1.0
			self.physicsBody = physicsBody
		}
	}
}
