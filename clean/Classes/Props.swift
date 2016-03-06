//
//  Props.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-02-24.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

enum Prop: String {
	case CKComb
	case CKCream
	case CKFoam
	case CKMouthwash
	case CKRazor
	case CKSoap
	case CKSoapDish
	case CKToothbrush
	case CKToothbrushStand
	case CKToothpaste
	case CKWax
}

extension LiftableObject {
	
	convenience init(propName: Prop) {
		
		self.init()
		
		let propName = "CleanKit.scnassets/props/\(propName.rawValue).dae"
		let scene = SCNScene(named: propName)!
		self.addChildNode(scene.rootNode.childNodes[0])
		
		self.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: SCNPhysicsShape(node: self, options: nil))
		self.physicsBody!.categoryBitMask = BitmaskLiftable
	}
}
