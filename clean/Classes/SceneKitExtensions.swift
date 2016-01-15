//
//  SceneKitExtensions.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-03.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

// MARK: SceneKit

extension SCNNode {
	var boundingBox: (min: SCNVector3, max: SCNVector3) {
		get {
			var min = SCNVector3(0, 0, 0)
			var max = SCNVector3(0, 0, 0)
			getBoundingBoxMin(&min, max: &max)
			return (min, max)
		}
	}
}

extension SCNPhysicsContact {
	func match(category category: Int, block: (matching: SCNNode, other: SCNNode) -> Void) {
		if self.nodeA.physicsBody!.categoryBitMask == category {
			block(matching: self.nodeA, other: self.nodeB)
		}
		
		if self.nodeB.physicsBody!.categoryBitMask == category {
			block(matching: self.nodeB, other: self.nodeA)
		}
	}
}

// MARK: Simd

extension float2 {
	init(_ v: CGPoint) {
		self.init(Float(v.x), Float(v.y))
	}
}

// MARK: CoreAnimation

extension CAAnimation {
	class func animationWithSceneNamed(name: String) -> CAAnimation? {
		var animation: CAAnimation?
		if let scene = SCNScene(named: name) {
			let armatureNode = scene.rootNode.childNodes[0]
			var duration: NSTimeInterval = 0
			var animations = []
			armatureNode.enumerateChildNodesUsingBlock({ (child, stop) in
				if child.animationKeys.count > 0 {
					for key in child.animationKeys {
						let animation = child.animationForKey(key)
						animations = animations.arrayByAddingObject(animation!)
						duration = max(duration, (animation?.duration)!)
					}
				}
			})
			let animationGroup = CAAnimationGroup()
			animationGroup.animations = animations as? [CAAnimation]
			animationGroup.duration = duration
			animation = animationGroup
		}
		return animation
	}
}
