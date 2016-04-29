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


enum VehicleWheel: String {
	case FrontRight = "wheel.front.r"
	case FrontLeft = "wheel.front.l"
	case BackRight = "wheel.back.r"
	case BackLeft = "wheel.back.l"
}

class Vehicle: SCNNode {
	
	private var armatureNode: SCNNode!
	private var bodyNode: SCNNode!
	private var flatBedNode: SCNNode!
	private var collisionNode: SCNNode!
	
	convenience init(type: VehicleType) {
		self.init()
		
		let truckNode = CleanKit.vehicleNodeNamed(type.rawValue)
		addChildNode(truckNode)
		
		let geometryNode = truckNode.childNodeWithName("geometry", recursively: true)!
		armatureNode = geometryNode.skinner!.skeleton!
		bodyNode = armatureNode.childNodeWithName("body", recursively: true)!
		flatBedNode = armatureNode.childNodeWithName("flatbed", recursively: true)!
		
		collisionNode = truckNode.collisionNode()
		let shape = SCNPhysicsShape(geometry: collisionNode.geometry!, options:[SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
		collisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: shape)
		collisionNode.physicsBody!.categoryBitMask = BitmaskDrivable | BitmaskCollision
		collisionNode.geometry = nil
		collisionNode.hidden = false
	}
	
	var directionAngle: CGFloat = 0.0 {
		didSet {
			
			// TODO: prevent axles from rotating more than +-20º
			// TODO: make wheels spin
			// TODO: make body respond to acceleration

			let directionAngleRadians = Float(directionAngle).degreesToRadians
			self.runAction(SCNAction.rotateToX(0, y: CGFloat(directionAngleRadians), z: 0, duration: 0, shortestUnitArc: true))
		}
	}
	
	var flatbedAngle: CGFloat = 0.0 {
		didSet {
			let flatbedAngleRadians = Float(flatbedAngle).degreesToRadians + Float(M_PI)
			flatBedNode.runAction(SCNAction.rotateToX(CGFloat(flatbedAngleRadians), y: 0, z: CGFloat(M_PI), duration: 0, shortestUnitArc: true))
		}
	}
	
	func wheelNode(name: VehicleWheel) -> SCNNode {
		return armatureNode.childNodeWithName(name.rawValue, recursively: true)!
	}
	
	class func vehicleFromCollisionNode(collisionNode: SCNNode) -> Vehicle {
		let truckNode = collisionNode.parentNode!
		let vehicle = truckNode.parentNode!
		return vehicle as! Vehicle
	}
	
	func entranceFromContactPoint(contactPoint: SCNVector3) -> VehicleEntrance {
		
		let localPoint = self.convertPosition(contactPoint, fromNode: nil)
		let (min, max) =  collisionNode.boundingBox
		let sidePadding: CGFloat = 0.01
		let sideIntersection = localPoint.x < (min.x + sidePadding) || localPoint.x > (max.x - sidePadding)
		let trunkIntersection = -localPoint.z < min.z
		
		if (sideIntersection) {
			return localPoint.x > 0 ? .Driver : .Passenger
		}
		else if (trunkIntersection) {
			return .Trunk
		}
	
		return .None
	}
	
	func beginDrivingFromEntrance(entrance: VehicleEntrance) {
		addAnimationForEntrance(entrance, open: true)
	}
	
	func endDrivingFromEntrance(entrance: VehicleEntrance) {
		addAnimationForEntrance(entrance, open: false)
	}
	
	private func addAnimationForEntrance(entrance: VehicleEntrance, open: Bool) {
		
		let state = open ? "Open" : "Close"
		let name = "CKTruck\(entrance.rawValue)\(state).dae"
		
		if (animationForKey(name) != nil) {
			return
		}
		
		let path = "CleanKit.scnassets/vehicles/\(name)"
		let animation = CAAnimation.animationWithSceneNamed(path)!
		addAnimation(animation, forKey: name)
	}
}
