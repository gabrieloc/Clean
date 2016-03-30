//
//  CleanKitHelpers.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

func CKPropNodeNamed(name: String) -> SCNNode {
	let path = "CleanKit.scnassets/props/\(name).dae"
	let scene = SCNScene(named: path)!
	return scene.rootNode.childNodes[0]
}

func CKVehicleNodeNamed(name: String) -> SCNNode {
	let path = "CleanKit.scnassets/vehicles/\(name).dae"
	let scene = SCNScene(named: path)!
	return scene.rootNode.childNodes[0]
}
