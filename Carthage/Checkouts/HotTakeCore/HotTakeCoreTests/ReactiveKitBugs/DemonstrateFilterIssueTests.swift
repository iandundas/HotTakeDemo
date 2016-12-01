//
//  DemonstrateFilterIssueTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble

class DemonstrateFilterIssueTests: XCTestCase {

    var collection: CollectionProperty<[Cat]>!
    let bag = DisposeBag()
    
    let catA = Cat(name: "Mr. A")
    let catB = Cat(name: "Mr. B")
    let catC = Cat(name: "Mr. C")
    
    
    override func setUp() {
        super.setUp()
        collection = CollectionProperty<[Cat]>([catA, catB])
    }
    
    override func tearDown() {
        bag.dispose()
        collection = nil
        super.tearDown()
    }
    
    func testStartingState() {
        expect(self.collection.count) == 2
    }
    
    func testUpdateWithoutFilter(){
        
        var updates = 0
        collection
            .observeNext { changes in
                updates += changes.deletes.count
            }.disposeIn(bag)
        
        collection.replace([catB, catA], performDiff: true)
        
        expect(updates).toEventually(equal(1))
    }
    
    func testUpdateWithFilter(){
        
        var updates = 0
        collection
            .filter {_ in true} // does nothing (in theory..)
            .observeNext { changes in
                updates += changes.deletes.count
            }.disposeIn(bag)
        
        collection.replace([catB, catA], performDiff: true)
        
        expect(updates).toEventually(equal(1))
    }
    
    func testDeleteWithoutFilter(){
        
        var deletes = 0
        collection
            .observeNext { changes in
                deletes += changes.deletes.count
            }.disposeIn(bag)
        
        collection.replace([catA], performDiff: true)
        
        expect(deletes).toEventually(equal(1))
    }
    
    func testDeleteWithFilter(){
        
        var deletes = 0
        collection
            .filter {_ in true} // does nothing (in theory..)
            .observeNext { changes in
                deletes += changes.deletes.count
            }.disposeIn(bag)
        
        collection.replace([catA], performDiff: true)
        
        expect(deletes).toEventually(equal(1)) // failed: expected to eventually equal <1>, got <0>
    }
}
