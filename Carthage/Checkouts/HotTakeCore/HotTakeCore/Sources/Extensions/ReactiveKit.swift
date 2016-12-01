//
//  ReactiveKit.swift
//  HotTakeCore
//
//  Created by Ian Dundas on 30/11/2016.
//  Copyright © 2016 Ian Dundas. All rights reserved.
//

import Foundation
import ReactiveKit

public extension CollectionChangeset{
    var hasNoMutations: Bool{
        return inserts.count == 0 && updates.count == 0 && deletes.count == 0
    }
}
