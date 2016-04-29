//
//  CleanKitHelpers.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-03-28.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//

import SceneKit

class CleanKit {
	
	class func propNodeNamed(name: String) -> SCNNode {
		let scene = SCNScene(named: CleanKit.pathForAssetNamed("\(name).dae", inDirectory: "props"))!
		let node = scene.rootNode.childNodes[0]
		node.applyDiffuseMaterials(name)
		return node
	}
	
	class func vehicleNodeNamed(name: String) -> SCNNode {
		let scene = SCNScene(named: CleanKit.pathForVehicleAssetNamed("\(name).dae"))!
		let node = scene.rootNode.childNodes[0]
		let geometryNode = node.childNodeWithName("geometry", recursively: true)!
		geometryNode.applyDiffuseMaterials(name)
		return node
	}
	
	class func pathForVehicleAssetNamed(name: String) -> String {
		return CleanKit.pathForAssetNamed(name, inDirectory: "vehicles")
	}
	
	internal class func pathForAssetNamed(name: String, inDirectory: String) -> String {
		return "CleanKit.scnassets/\(inDirectory)/\(name)"
	}
}

private extension SCNNode {
	
	func applyDiffuseMaterials(name: String) {
		geometry?.materials.forEach({ (material) in
			let path = CleanKit.pathForAssetNamed("\(name).png", inDirectory: "textures")
			material.diffuse.contents = path
			
			if material.name == "window" || material.name == "glass" {
				material.transparency = 0.25
			}
		})
	}
}