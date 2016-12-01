//
//  Cat.swift
//  ReactiveKit2
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit

public class Cat {
    public let name: String
    public let miceEaten: Int
    public let id: String = NSUUID().UUIDString
    
    public init(name: String, miceEaten: Int = 0){
        self.name = name
        self.miceEaten = miceEaten
    }
}

extension Cat: Equatable{
}

public func ==(a: Cat, b: Cat) -> Bool {
    return a.id == b.id
}
