//
//  Character.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

enum GroundType: Int {
	case InTheAir
}

class Character {
	
	init() {
		let characterScene = SCNScene(named: "game.scnassets/baby/idle.scn")!
		let characterTopLevelNode = characterScene.rootNode.childNodes[0]
		node.addChildNode(characterTopLevelNode)
		
		let (min, max) = node.boundingBox
		let collisionCapsuleRadius = CGFloat(max.x - min.x) * 0.4
		let collisionCapsuleHeight = CGFloat(max.y - min.y)
		
		let characterCollisionNode = SCNNode()
		characterCollisionNode.name = "collider"
		characterCollisionNode.position = SCNVector3(0.0, collisionCapsuleHeight * 0.51, 0.0)
		characterCollisionNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape:SCNPhysicsShape(geometry: SCNCapsule(capRadius: collisionCapsuleRadius, height: collisionCapsuleHeight), options:nil))
		characterCollisionNode.physicsBody!.contactTestBitMask = BitmaskCollision
		node.addChildNode(characterCollisionNode)
		
		walkAnimation = CAAnimation.animationWithSceneNamed("game.scnassets/baby/run.scn")
		walkAnimation.usesSceneTimeBase = false
		walkAnimation.fadeInDuration = 0.3
		walkAnimation.fadeOutDuration = 0.3
		walkAnimation.repeatCount = Float.infinity
		walkAnimation.speed = Character.speedFactor
		walkAnimation.animationEvents = [
			SCNAnimationEvent(keyTime: 0.1) { (_, _, _) in self.playFootStep() },
			SCNAnimationEvent(keyTime: 0.6) { (_, _, _) in self.playFootStep() }
		]
	}
	
	let node = SCNNode()
	
	// MARK: Movement
	
	static let speedFactor = Float(2.5)
	private var groundType = GroundType.InTheAir
	private var previousUpdateTime = NSTimeInterval(0.0)
	private var accelerationY = SCNFloat(0.0) // gravity simulation

	private var directionAngle: SCNFloat = 0.0 {
		didSet {
			if directionAngle != oldValue {
				node.runAction(SCNAction.rotateToX(0.0, y: CGFloat(directionAngle), z: 0.0, duration: 0.1, shortestUnitArc: true))
			}
		}
	}
	
	func walkInDirection(direction: float3, time: NSTimeInterval, scene: SCNScene) -> SCNNode? {
		if previousUpdateTime == 0.0 {
			previousUpdateTime = time
		}
		
		let deltaTime = Float(min(time - previousUpdateTime, 1.0 / 60.0))
		let characterSpeed = deltaTime * Character.speedFactor
		previousUpdateTime = time
		
		// move
		if direction.x != 0.0 && direction.z != 0.0 {
			let position = float3(node.position)
			node.position = SCNVector3(position + direction * characterSpeed)
			directionAngle = SCNFloat(atan2(direction.x, direction.z))
			isWalking = true
		}
		else {
			isWalking = false
		}
		
		// altitude
		
		var position = node.position
		var p0 = position
		var p1 = position
		
		let maxRise = SCNFloat(0.08)
		let maxJump = SCNFloat(10.0)
		p0.y -= maxJump
		p1.y += maxRise
		
		// Do a vertical ray intersection
		var groundNode: SCNNode?
		let results = scene.physicsWorld.rayTestWithSegmentFromPoint(p1, toPoint: p0, options:[SCNPhysicsTestCollisionBitMaskKey: BitmaskCollision, SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest])
		
		if let result = results.first {
			let groundAltitude = result.worldCoordinates.y
			groundNode = result.node
			
			let threshold = SCNFloat(1e-5)
			let gravityAcceleration = SCNFloat(0.18)
			if groundAltitude < position.y - threshold {
				accelerationY += SCNFloat(deltaTime) * gravityAcceleration
				if groundAltitude < position.y - 0.2 {
					groundType = .InTheAir
				}
			}
			else {
				accelerationY = 0
			}
			
			position.y -= accelerationY
			
			if groundAltitude > position.y {
				accelerationY = 0
				position.y = groundAltitude
			}
			
//			print(position)
			node.position = position
		}
		else {
			// error moving character, revert to initial position
//			node.position = initialPosition
		}

		return groundNode
	}
	
	// MARK: Animations
	
	private var walkAnimation: CAAnimation!
	private var isWalking: Bool = false {
		didSet {
			if oldValue != isWalking {
				if isWalking {
					node.addAnimation(walkAnimation, forKey: "walk")
				} else {
					node.removeAnimationForKey("walk", fadeOutDuration: 0.2)
				}
			}
		}
	}
	
	// MARK: Sound
	
	private func playFootStep() {
		//TODO
	}
}
