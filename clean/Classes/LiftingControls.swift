//
//  LiftingControls.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-09.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class LiftingControls: SCNNode {
	
	override init() {
		super.init()
		
		self.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
		self.geometry!.firstMaterial?.diffuse.contents = blueColor()
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}