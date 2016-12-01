//
//  ManualDatasource.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble

@testable import HotTakeCore

/* 
 Rules: 
  - Observers should receive the current contents of the internal container in an "initial" notification.
  - Observers should receive correct diff notifications when things change
 */

class ManualDatasourceTests: XCTestCase {

    let catA = Cat(name: "Mr A")
    let catB = Cat(name: "Mr B")
    let catC = Cat(name: "Mr C")

    var emptyArray: [Cat]!
    var nonEmptyArray: [Cat]!
    
    let bag = DisposeBag()
    
    var datasource: ManualDataSource<Cat>!
    
    override func setUp() {
        super.setUp()
        emptyArray = []
        nonEmptyArray = [catA]
    }
    
    override func tearDown() {
        datasource = nil
        bag.dispose()
        super.tearDown()
    }
    
    func testInitialNotificationIsReceived(){
        datasource = ManualDataSource<Cat>(items: [catA, catB])
        
        
        var (inserts, deletes, updates) = (-1,-1,-1)
        
        datasource.mutations().observeNext { changes in
            // We identify initial notification as being when inserts == 0, deletes == 0, updates == 0
            inserts = changes.inserts.count
            deletes = changes.deletes.count
            updates = changes.updates.count
        }.disposeIn(bag)
        
        expect(inserts).toEventually(equal(0))
        expect(deletes).toEventually(equal(0))
        expect(updates).toEventually(equal(0))
    }
    
    func testInsertEventIsReceived(){
        datasource = ManualDataSource<Cat>(items: [catA, catB])
        var (inserts, deletes, updates) = (-1,-1,-1)
        
        datasource.mutations().observeNext { changes in
            inserts = changes.inserts.count
            deletes = changes.deletes.count
            updates = changes.updates.count
        }.disposeIn(bag)
        
        datasource.replaceItems([catA, catB, catC])

        expect(inserts).toEventually(equal(1))
        expect(deletes).toEventually(equal(0))
        expect(updates).toEventually(equal(0))
    }
    
    func testDeleteEventIsReceived(){
        datasource = ManualDataSource<Cat>(items: [catA, catB])
        var (inserts, deletes, updates) = (-1,-1,-1)
        
        datasource.mutations().observeNext { changes in
            inserts = changes.inserts.count
            deletes = changes.deletes.count
            updates = changes.updates.count
        }.disposeIn(bag)
        
        datasource.replaceItems([])
        
        expect(inserts).toEventually(equal(0))
        expect(deletes).toEventually(equal(2)) // see ReactiveKitBugs/DemonstrateFilterIssueTests
        expect(updates).toEventually(equal(0))
    }
    
    
    func testBasicInsertBindingWhereObserverIsBoundBeforeInsert() {
        datasource = ManualDataSource<Cat>(items: [])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        datasource.replaceItems([catA])
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(1), timeout: 2)
    }
    
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelay() {
        datasource = ManualDataSource<Cat>(items: [])
        
        datasource.replaceItems([catA])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithADelay() {
        datasource = ManualDataSource<Cat>(items: [])
        
        datasource.replaceItems([catA])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        Queue.main.after(1){
            self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
            self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }
    
    
    
    func testBasicInsertBindingWhereObserverIsBoundBeforeInsertAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        datasource.replaceItems([catA, catB])
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(1), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelayAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems([catA, catB])
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }
    
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithADelayAndAnItemIsAlreadyAdded() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems([catA, catB])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        Queue.main.after(1){
            self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
            self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }
    
    
    func testBasicDeleteWhereColletionIsEmptyWhenObservingAfterwards() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        datasource.replaceItems([])
        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
        self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }
    
    func testBasicDeleteWhereColletionEmptiesAfterObservingBeforehand() {
        datasource = ManualDataSource<Cat>(items: [catA])
        
        let firstChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
        let secondChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        
        datasource.replaceItems([])
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        expect(secondChangeset.value?.deletes.count).toEventually(equal(1), timeout: 2)
    }
    
    
//    func testBasicUpdateWhereCollectionIsObservingBeforehandAfterDelay() {
//        datasource = ManualDataSource<Cat>(items: [catA])
//        
//        datasource.mutations().observeNext {event in
//            print("event: \(event)")
//        }
//        let firstChangeset = ChangesetProperty(nil)
//        self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
//        let secondChangeset = ChangesetProperty(nil)
//        self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
//        
//        Queue.main.after(1){
//            self.catA.name = "miss miggins"
//            self.datasource.replaceItems([self.catA])
//        }
//        
//        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
//        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
//        expect(firstChangeset.value?.updates.count).toEventually(equal(0), timeout: 2)
//        expect(firstChangeset.value?.deletes.count).toEventually(equal(0), timeout: 2)
//        
//        expect(secondChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
//        expect(secondChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
//        expect(secondChangeset.value?.updates.count).toEventually(equal(1), timeout: 2)
//        expect(secondChangeset.value?.deletes.count).toEventually(equal(0), timeout: 2)
//        
//    }
    

}
