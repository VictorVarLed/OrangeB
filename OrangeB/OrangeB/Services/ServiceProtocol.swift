//
//  ServiceProtocol.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import Foundation

// Here we define a protocol to detail all the methods a Service should implement
public protocol ServiceProtocol {
    static func start()
    static func stop()
    static func isRunning() -> Bool
}
