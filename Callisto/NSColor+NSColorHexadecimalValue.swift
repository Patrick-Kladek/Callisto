//
//  NSColor+NSColorHexadecimalValue.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

extension NSColor {

    func hexValue() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rHex = Int(r*255)<<16
        let gHex = Int(g*255)<<8
        let bHex = Int(b*255)<<0

        let rgb: Int =  rHex | gHex | bHex
        return String(format:"#%06x", rgb)
    }
}
