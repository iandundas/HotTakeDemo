//
//  DatasourceContainerWithManualTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble

@testable import HotTakeCore

class DatasourceContainerWithManualTests: XCTestCase {

    let bag = DisposeBag()
    
    let emptyCollection = [Cat]()
    
    let nonemptyCollection = [
        Cat(name: "Mr A"),
        Cat(name: "Mr B"),
        Cat(name: "Mr C"),
    ]
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        bag.dispose()
        super.tearDown()
    }

    func testInitialEventWhenStartingWithEmptyCollection(){
        
        let dsc = ManualDataSource<Cat>(items: []).encloseInContainer()
        
        var detectedInitialEvent = false
        dsc.collection.observeNext { changes in
            guard changes.hasNoMutations else {fail("Should be initial event"); return}
            guard changes.collection.count == 0 else {fail("Should have been an empty initial collection");return}
            let noMutations = changes.hasNoMutations
            detectedInitialEvent = noMutations
            
        }.disposeIn(bag)
        
        expect(detectedInitialEvent).toEventually(beTrue())
    }
        
    func testInitialEventWhenStartingWithNonemptyCollection(){
        
        let dsc = ManualDataSource<Cat>(items: nonemptyCollection).encloseInContainer()
        
        var initialItems = [Cat]()
        var detectedInitialEvent = false
        dsc.collection.observeNext { changes in
            guard changes.hasNoMutations else {fail("Should be initial event"); return}
            let noMutations = changes.hasNoMutations
            detectedInitialEvent = noMutations
            
            initialItems = changes.collection
        }.disposeIn(bag)
    
        expect(detectedInitialEvent).toEventually(beTrue())
        expect(initialItems).toEventually(equal(nonemptyCollection))
    }

    // Expecting a single corrected initial event, rather than any reported updates
    func testInitialEventWhenObservingAfterInsertingOnAnEmptyDataSource(){
        
        let datasource = ManualDataSource<Cat>(items: emptyCollection)
        let dsc = datasource.encloseInContainer()
        
        datasource.replaceItems(nonemptyCollection)
        
        var initialItems = [Cat]()
        var detectedInitialEvent = false
        dsc.collection.observeNext { changes in
            guard changes.hasNoMutations else {fail("Should be initial event"); return}
            detectedInitialEvent = changes.hasNoMutations
            
            initialItems = changes.collection
        }.disposeIn(bag)
        
        expect(detectedInitialEvent).toEventually(beTrue())
        expect(initialItems).toEventually(equal(nonemptyCollection))
    }
    
    func testInitialSubscriptionSendsASingleCurrentStateEventWhenInitiallyObserved(){
        
        var observeCallCount = 0
        var inserted = false
        var updated = false
        var deleted = false
        
        let container = ManualDataSource<Cat>(items: [Cat]()).encloseInContainer()
        
        container.collection
            .observeNext { changes in
                guard changes.hasNoMutations else {fail("Should be initial event"); return}
                
                observeCallCount += 1
                
                inserted = inserted || changes.inserts.count > 0
                updated = updated || changes.updates.count > 0
                deleted = deleted || changes.deletes.count > 0
                
            }.disposeIn(bag)
        
        expect(observeCallCount).toEventually(equal(1), timeout: 1)
        expect(inserted).toEventually(equal(false), timeout: 1)
        expect(updated).toEventually(equal(false), timeout: 1)
        expect(deleted).toEventually(equal(false), timeout: 1)
    }
    
}

