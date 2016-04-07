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
	
	private var bodyNode: SCNNode!
	private var frontDirectionNode: SCNNode!
	private var backDirectionNode: SCNNode!
	
	convenience init(type: VehicleType) {
		self.init()
		
		let truckNode = CKVehicleNodeNamed(type.rawValue)
		addChildNode(truckNode)
		
		let geometryNode = truckNode.childNodeWithName("geometry", recursively: true)!
		let armature = geometryNode.skinner!.skeleton!
		bodyNode = armature.childNodeWithName("body", recursively: false)
		frontDirectionNode = armature.childNodeWithName("wheels.direction.front", recursively: false)!
		backDirectionNode = armature.childNodeWithName("wheels.direction.back", recursively: false)!
		
		let collisionNode = truckNode.collisionNode()
		let shape = SCNPhysicsShape(geometry: collisionNode.geometry!, options:nil)
		collisionNode.physicsBody = SCNPhysicsBody(type: .Kinematic, shape: shape)
		collisionNode.physicsBody!.categoryBitMask = BitmaskDrivable
		collisionNode.geometry = nil
		collisionNode.hidden = false
	}
	
	var directionAngle: CGFloat = 0.0 {
		didSet {
			
//			print(directionAngle)
			frontDirectionNode.runAction(SCNAction.rotateToX(0, y: directionAngle, z: 0, duration: 0, shortestUnitArc: true))
			
			self.runAction(SCNAction.rotateToX(0, y: directionAngle, z: 0, duration: 0, shortestUnitArc: true))
//			backDirectionNode.runAction(SCNAction.rotateToX(0, y: directionAngle * 0.95, z: 0, duration: 0, shortestUnitArc: true))
			
//			self.rotation = SCNVector4(x: 0, y: 1, z: 0, w: CGFloat(2 * M_PI))
//			rootNode.rotation = SCNVector4(x: 0, y: 0.9, z: 0, w: CGFloat(2 * M_PI))
//			frontDirectionNode.rotation = SCNVector4(x: 0, y: 1.0, z: 0, w: CGFloat(2 * M_PI))
//			backDirectionNode.rotation = SCNVector4(x: 0, y: 0.9, z: 0, w: CGFloat(2 * M_PI))
		}
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
