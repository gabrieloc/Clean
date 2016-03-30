//
//  Vehicle.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

enum VehicleType: String {
	case CKTruck
}

class Vehicle: SCNNode {
	
	convenience init(type: VehicleType) {
		self.init()
		
		let truckNode = CKVehicleNodeNamed(type.rawValue)
		addChildNode(truckNode)
		
		let collisionNode = truckNode.collisionNode()
		let shape = SCNPhysicsShape(geometry: collisionNode.geometry!, options:nil)
		collisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: shape)
		collisionNode.physicsBody!.categoryBitMask = BitmaskDrivable
		collisionNode.geometry = nil
		collisionNode.hidden = false
	}
	
	class func vehicleFromCollisionNode(collisionNode: SCNNode) -> Vehicle {
		let truckNode = collisionNode.parentNode!
		let vehicle = truckNode.parentNode!
		return vehicle as! Vehicle
	}
}
