//
//  RealmDatasourceTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit
import XCTest
import RealmSwift
import ReactiveKit
import Nimble
import HotTakeCore

@testable import HotTakeRealm

class RealmDatasourceTests: XCTestCase {

    var emptyRealm: Realm!
    var nonEmptyRealm: Realm!
    
    var bag: DisposeBag!
    
    var datasource: RealmDataSource<Cat>!
    
    override func setUp() {
        super.setUp()
        bag = DisposeBag()
        
        nonEmptyRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: NSUUID().UUIDString))
        emptyRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: NSUUID().UUIDString))
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name" : "Cat A", "miceEaten": 0]))
        }
    }
    
    override func tearDown() {
        bag.dispose()
        
        emptyRealm = nil
        nonEmptyRealm = nil
        
        datasource = nil
        super.tearDown()
    }

    func testBasicInsertBindingWhereObserverIsBoundBeforeInsert() {
        datasource = RealmDataSource<Cat>(items:emptyRealm.objects(Cat))

        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(1), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelay() {
        datasource = RealmDataSource<Cat>(items:emptyRealm.objects(Cat))
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
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
        datasource = RealmDataSource<Cat>(items:emptyRealm.objects(Cat))
        
        try! emptyRealm.write {
            emptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
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
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        let firstChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(0).bindTo(firstChangeset)
        
        let secondChangeset = ChangesetProperty(nil)
        datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(2), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(1), timeout: 2)
    }
    
    func testBasicInsertBindingWhereObserverIsBoundAfterInsertWithoutDelayAndAnItemIsAlreadyAdded() {
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
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
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        try! nonEmptyRealm.write {
            nonEmptyRealm.add(Cat(value: ["name" : "Mr Cow"]))
        }
        
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
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        try! nonEmptyRealm.write {
            datasource.items().forEach(nonEmptyRealm.delete)
        }
        
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
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        let firstChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
        let secondChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        
        try! nonEmptyRealm.write {
            datasource.items().forEach(nonEmptyRealm.delete)
        }

        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        
        expect(secondChangeset.value?.collection.count).toEventually(equal(0), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        expect(secondChangeset.value?.deletes.count).toEventually(equal(1), timeout: 2)
    }
    
    
    func testBasicUpdateWhereCollectionIsObservingBeforehandAfterDelay() {
        datasource = RealmDataSource<Cat>(items:nonEmptyRealm.objects(Cat))
        
        let firstChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(0).bindTo(firstChangeset)
        let secondChangeset = ChangesetProperty(nil)
        self.datasource.mutations().elementAt(1).bindTo(secondChangeset)
        
        Queue.main.after(1){
            let item = self.datasource.items()[0]
            try! self.nonEmptyRealm.write {
                item.name = "new name"
            }
        }
        
        expect(firstChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(firstChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.updates.count).toEventually(equal(0), timeout: 2)
        expect(firstChangeset.value?.deletes.count).toEventually(equal(0), timeout: 2)

        expect(secondChangeset.value?.collection.count).toEventually(equal(1), timeout: 2)
        expect(secondChangeset.value?.inserts.count).toEventually(equal(0), timeout: 2)
        expect(secondChangeset.value?.updates.count).toEventually(equal(1), timeout: 2)
        expect(secondChangeset.value?.deletes.count).toEventually(equal(0), timeout: 2)

    }
    
}
