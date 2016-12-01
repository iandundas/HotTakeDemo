//
//  DataSource.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import Foundation
import ReactiveKit

public protocol DataSourceType {
    associatedtype ItemType : Equatable

    // Access a (currently unsorted) array of items:
    func items() -> [ItemType]

    // Access a feed of mutation events:
    func mutations() -> Stream<CollectionChangeset<[ItemType]>>

    func encloseInContainer() -> Container<ItemType>
    
    func eraseType() -> AnyDataSource<ItemType>
}

public extension DataSourceType{
    public func encloseInContainer() -> Container<ItemType>{
        let wrapper = AnyDataSource(self)
        let datasourceContainer = Container(datasource: wrapper)
        return datasourceContainer
    }
    public func eraseType() -> AnyDataSource<ItemType>{
        return AnyDataSource(self)
    }
    
//    public func postSort(isOrderedBefore: (ItemType, ItemType) -> Bool) -> AnyDataSource<ItemType>{
//        let wrapper = AnyDataSource(self)
//        let postsort = PostSortDataSource(datasource: wrapper, isOrderedBefore: isOrderedBefore)
//        return AnyDataSource(postsort)
//    }
}
