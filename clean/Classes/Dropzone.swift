//
//  Dropzone.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-01-24.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class Dropzone : SCNNode {
	
	override init()
	{
		super.init()

		let geometry = SCNPlane(width: 1, height: 1)
		geometry.firstMaterial?.diffuse.contents = NSColor.yellowColor()
		self.geometry = geometry
		self.rotation = SCNVector4Make(-1, 0, 0, CGFloat(M_PI / 2.0))
		self.position = SCNVector3Make(0, 0.001, 2)
	}
	
	required init(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}