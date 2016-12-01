//
//  ContainerTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 15/05/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble
import RealmSwift
import HotTakeCore

@testable import HotTakeRealm

typealias ChangesetProperty = ReactiveKit.Property<CollectionChangeset<[Cat]>?>

class ContainerWithRealmTests: XCTestCase {
    
    var emptyRealm: Realm!
    var nonEmptyRealm: Realm!
    
    var disposeBag = DisposeBag()
    
    var container: Container<Cat>!
    
    override func setUp() {
        super.setUp()
        
        nonEmptyRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: NSUUID().UUIDString))
        emptyRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: NSUUID().UUIDString))
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name" : "Cat A", "miceEaten": 0]))
            nonEmptyRealm.add(Cat(value: ["name" : "Cat D", "miceEaten": 3]))
            nonEmptyRealm.add(Cat(value: ["name" : "Cat M", "miceEaten": 5]))
            nonEmptyRealm.add(Cat(value: ["name" : "Cat Z", "miceEaten": 100]))
        }
    }
    
    override func tearDown() {
        disposeBag.dispose()
        
        emptyRealm = nil
        nonEmptyRealm = nil
        
        container = nil
        
        super.tearDown()
    }
    
    func testBasicInsertBindingWhereObserverIsBoundBeforeInsert() {
        container = RealmDataSource<Cat>(items:emptyRealm.objects(Cat)).encloseInContainer()
        
        let firstChangeset = ChangesetProperty(nil)
        container.collection.elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        container.collection.elementAt(1).bindTo(secondChangeset)
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
            emptyRealm.add(Cat(value: ["name" : "Mr Lolz"]))
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(2), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelay() {
        container = RealmDataSource<Cat>(items:emptyRealm.objects(Cat)).encloseInContainer()

        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
            emptyRealm.add(Cat(value: ["name" : "Mr Lolz"]))
        }

        let firstChangeset = ChangesetProperty(nil)
        container.collection.elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        container.collection.elementAt(1).bindTo(secondChangeset)
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(2), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithADelay() {
        container = RealmDataSource<Cat>(items:emptyRealm.objects(Cat)).encloseInContainer()
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
            emptyRealm.add(Cat(value: ["name" : "Mr Lolz"]))
        }

        
        let firstChangeset = ChangesetProperty(nil)
        let secondChangeset = ChangesetProperty(nil)
        
        Queue.main.after(1){
            self.container.collection.elementAt(0).bindTo(firstChangeset)
            self.container.collection.elementAt(1).bindTo(secondChangeset)
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(beNil(), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(beNil(), timeout: 2)
    }    
    
    /* Test it sends a single event containing 0 insert, 0 update, 0 delete when initially an empty container */
    func testInitialSubscriptionSendsASingleCurrentStateEventWhenInitiallyEmpty(){
        
        var observeCallCount = 0
        var inserted = false
        var updated = false
        var deleted = false
        
        container = RealmDataSource<Cat>(items: emptyRealm.objects(Cat)).encloseInContainer()
        
        container.collection
            .observeNext { changes in
                guard changes.hasNoMutations else {fail("Must be an initial event"); return}
                
                observeCallCount += 1
                
                inserted = inserted || changes.inserts.count > 0
                updated = updated || changes.updates.count > 0
                deleted = deleted || changes.deletes.count > 0
                
            }.disposeIn(disposeBag)
        
        expect(observeCallCount).toEventually(equal(1), timeout: 1)
        expect(inserted).toEventually(equal(false), timeout: 1)
        expect(updated).toEventually(equal(false), timeout: 1)
        expect(deleted).toEventually(equal(false), timeout: 1)
    }
    
    
    /* Test it sends an event containing 0 insert, 0 update, 0 delete when initially non-empty container */
    func testInitialSubscriptionSendsASingleCurrentStateEventWhenInitiallyNonEmpty(){
        
        container = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat)).encloseInContainer()
        
        var observeCallCount = 0
        var inserted = false
        var updated = false
        var deleted = false
        
        container.collection
            .observeNext { changes in
                guard changes.hasNoMutations else {fail("Must be an initial event"); return}
                
                observeCallCount += 1
                
                inserted = inserted || changes.inserts.count > 0
                updated = updated || changes.updates.count > 0
                deleted = deleted || changes.deletes.count > 0
                
            }.disposeIn(disposeBag)
        
        expect(observeCallCount).toEventually(equal(1), timeout: 1)
        expect(inserted).toEventually(equal(false), timeout: 1)
        expect(updated).toEventually(equal(false), timeout: 1)
        expect(deleted).toEventually(equal(false), timeout: 1)
    }
    
    func testReplacingEmptyDatasourceWithAnotherEmptyDatasourceProducedNoUpdateSignals(){
        
        let emptyRealmDataSource = RealmDataSource<Cat>(items:emptyRealm.objects(Cat))
        let emptyManualDataSource = ManualDataSource(items: [Cat]())
        
        container = emptyRealmDataSource.encloseInContainer()
        
        var observeCallCount = 0
        
        container.collection
            .observeNext { changes in
                observeCallCount += 1
            }.disposeIn(disposeBag)
        
        // replace with another, identical datasource:
        container.datasource = emptyManualDataSource.eraseType()
        
        // important because second one can be mistaken for an .Initial event (0,0,0) and we don't want 2x .Initial events.
        // i.e. expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(1), timeout: 3)
    }
    
    func testReplacingEmptyDatasourceWithAnotherEmptyDatasourceAndAddingItemsToInitialDataSourceProducesNoUpdateSignals(){
        
        let emptyRealmDataSource = AnyDataSource(RealmDataSource<Cat>(items:emptyRealm.objects(Cat)))
        let emptyManualDataSource = AnyDataSource(ManualDataSource(items: [Cat]()))
        
        var observeCallCount = 0
        
        container = Container(datasource: emptyRealmDataSource)
        container.collection
            .observeNext { changes in
                observeCallCount += 1
            }.disposeIn(disposeBag)
        
        container.datasource = emptyManualDataSource
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Catzz"]))
        }
    
        // expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(1), timeout: 3)
        
    }
    
    func testReplacingNonEmptyDatasourceWithAnIdenticalNonEmptyDatasourceProducedNoUpdateSignals(){
        
        let nonemptyRealmDataSourceA = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        container = nonemptyRealmDataSourceA.encloseInContainer()
        
        var observeCallCount = 0
        
        container.collection
            .observeNext { changes in
                observeCallCount += 1
            }.disposeIn(disposeBag)
        
        // replace with another, identical datasource:
        let nonemptyRealmDataSourceB = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        container.datasource = nonemptyRealmDataSourceB.eraseType()
        
        // important because second one can be mistaken for an .Initial event (0,0,0) and we don't want 2x .Initial events.
        // i.e. expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(1), timeout: 3)
    }
    
    func testReplacingNonEmptyDatasourceWithAnEmptyDatasourceProducesCorrectDeleteSignals(){
        
        var observeCallCount = 0
        var deleteCount = 0
        
        // contains 4 items
        container = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat)).encloseInContainer()
        container.collection
            .observeNext { changes in
                observeCallCount += 1
                deleteCount += changes.deletes.count
                
            }.disposeIn(disposeBag)
        
        // Contains 0 items
        let emptyManualDataSource = AnyDataSource(ManualDataSource(items: [Cat]()))
        container.datasource = emptyManualDataSource
        
        // expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(2), timeout: 3)
        expect(deleteCount).toEventually(equal(4), timeout: 3)
        
    }
    
    func testReplacingEmptyDatasourceWithANonEmptyDatasourceProducesCorrectInsertSignals(){
        
        var observeCallCount = 0
        var insertCount = 0
        
        // contains 0 items
        container = ManualDataSource(items: [Cat]()).encloseInContainer()
        container.collection
            .observeNext { changes in
                observeCallCount += 1
                insertCount += changes.inserts.count
                
            }.disposeIn(disposeBag)
        
        // replace with a datasource containing 4 items:
        let nonEmptyRealmDataSource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat)).eraseType()
        container.datasource = nonEmptyRealmDataSource
        
        // expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(2), timeout: 3)
        expect(insertCount).toEventually(equal(4), timeout: 3)
    }
    
    
    func testReplacingNonEmptyDatasourceWithAnotherNonEmptyDatasourceContainingSomeDifferentItemsProducesCorrectMutationSignals(){
        
        let dataSourceA = AnyDataSource(RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat).filter("miceEaten < 5"))) // 2 items (0, 3)
        let dataSourceB = AnyDataSource(RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat).filter("miceEaten > 0"))) // 3 items (   3, 5, 100)
        
        var observeCallCount = 0
        var insertCount = 0
        var updateCount = 0
        var deleteCount = 0
        
        container = Container(datasource: dataSourceA)
        container.collection
            .observeNext { changes in
                observeCallCount += 1
                insertCount += changes.inserts.count
                updateCount += changes.updates.count
                deleteCount += changes.deletes.count
                
            }.disposeIn(disposeBag)
        
        container.datasource = dataSourceB
        
        // expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(2), timeout: 3)
        expect(insertCount).toEventually(equal(2), timeout: 3)
        expect(updateCount).toEventually(equal(0), timeout: 3)
        expect(deleteCount).toEventually(equal(1), timeout: 3)
    }
    
    func testInsertingWhilstReplacingNonEmptyDatasourceWithAnotherNonEmptyDatasourceContainingCertainDifferentItemsProducesCorrectMutationSignals2(){
        
        // 2 items (0, 3)
        let dataSourceA = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat).filter("miceEaten < 5")).eraseType()
        
        // 3 items (   3, 5, 100)
        let dataSourceB = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat).filter("miceEaten > 0")).eraseType()
        
        var observeCallCount = 0
        var insertCount = 0
        var updateCount = 0
        var deleteCount = 0
        
        container = Container(datasource: dataSourceA)
        container.collection
            .observeNext { changes in
                if observeCallCount == 0 && !changes.hasNoMutations{
                    fail("First event should be an initial event")
                }
                if observeCallCount > 0 && changes.hasNoMutations{
                    fail("Subsequent events should not identify as first")
                }
                
                observeCallCount += 1
                insertCount += changes.inserts.count
                updateCount += changes.updates.count
                deleteCount += changes.deletes.count
                
            }.disposeIn(disposeBag)
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name": "fluffy", "miceEaten": 0])) // skipped from seeig in insert due to same Run loop as datasource swap
            nonEmptyRealm.add(Cat(value: ["name": "this one should appear", "miceEaten": 1000]))
        }
        
        container.datasource = dataSourceB
        
        // expect only to have the initial insert changeset (when first binded) and not the subsequent insert.
        expect(observeCallCount).toEventually(equal(2), timeout: 3)
        expect(insertCount).toEventually(equal(3), timeout: 3)
        expect(updateCount).toEventually(equal(0), timeout: 3)
        expect(deleteCount).toEventually(equal(1), timeout: 3)
    }
}
