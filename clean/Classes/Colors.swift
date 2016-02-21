//
//  Colors.swift
//  clean
//
//  Created by Gabriel O'Flaherty-Chan on 2016-02-18.
//  Copyright © 2016 Gabrieloc. All rights reserved.
//


#if os(iOS) || os(tvOS)
	import UIKit
	typealias Color = UIColor
#elseif os(OSX)
	import AppKit
	typealias Color = NSColor
#endif

func yellowColor() -> Color {
	return Color.yellowColor()
}

func blueColor() -> Color {
	return Color.blueColor()
}
