//
//  Cat.swift
//  ReactiveKit2
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit
import RealmSwift


class Cat: Object {
    dynamic var name = ""
    dynamic var miceEaten: Int = 0
    
    dynamic var id: String = NSUUID().UUIDString
    override static func primaryKey() -> String? {
        return "id"
    }
}


//extension Cat: Equatable{}

func ==(lhs: Cat, rhs: Cat) -> Bool{
    return lhs.name == rhs.name
}

//func <(lhs: Cat, rhs: Cat) -> Bool{
//    return true
//}
//
//func <=(lhs: Cat, rhs: Cat) -> Bool{
//    return true
//}
//
//func >=(lhs: Cat, rhs: Cat) -> Bool{
//    return true
//}
//
//func >(lhs: Cat, rhs: Cat) -> Bool{
//    return true
//}


