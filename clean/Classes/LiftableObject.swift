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
		object.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
		object.physicsBody!.categoryBitMask = BitmaskLiftable
		
		return object
	}
	
	func setupPhysicsBody() {
		
	}
}
