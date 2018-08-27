//
//  Utils.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//
// This Utils class has some extensions to make our life easier :)

import Foundation

extension NSObject{
    public class func getName()->String {
        let classString = NSStringFromClass(self)
        if let range = classString.range(of: "."){
            return String(classString[range.upperBound...])
        }
        return classString
    }
}
