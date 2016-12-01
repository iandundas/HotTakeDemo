//
//  ManualDataSource.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 30/11/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import Foundation
import ReactiveKit

public class ManualDataSource<Item: Equatable>: DataSourceType {
    
    public func items() -> [Item] {
        return collection.filter{_ in true}
    }
    
    // only available publicly on ManualDataSource (because it's.. manual)
    public func replaceItems(items: [Item]) {
        collection.replace(items, performDiff: true)
    }
    
    public func mutations() -> Stream<CollectionChangeset<[Item]>>{
        return collection.filter {_ in true}
    }
    
    private let collection: CollectionProperty<Array<Item>>
    
    /* TODO: currently only takes Array CollectionType
     init<C: CollectionType where C.Generator.Element == Element>(collection: C){
     self.collection = CollectionProperty<C>(collection)
     }
     */
    
    public init(items: [Item]){
        self.collection = CollectionProperty(items)
    }
}
