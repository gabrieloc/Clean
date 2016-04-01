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

enum VehicleEntrance: String {
	case None = ""
	case Driver = "DriverSide"
	case Passenger = "PassengerSide"
	case Trunk = "Trunk"
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
	
	func entranceFromContactPoint(contactPoint: SCNVector3) -> VehicleEntrance {
		
		let localPoint = self.convertPosition(contactPoint, fromNode: nil)
		let (min, max) = boundingBox
		let sidePadding: CGFloat = 0.1
		let sideIntersection = localPoint.x < (min.x + sidePadding) || localPoint.x > (max.x - sidePadding)
		let trunkIntersection = -localPoint.z < min.z
		
		if (sideIntersection) {
			return localPoint.x > 0 ? .Passenger : .Driver
		}
		else if (trunkIntersection) {
			return .Trunk
		}
	
		return .None
	}
	
	func beginDrivingFromEntrance(entrance: VehicleEntrance) {
		
	}
	
	func endDrivingFromEntrance(entrance: VehicleEntrance) {
		
	}
}
