//
//  ProveOperationToStreamIssueTests.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/06/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import XCTest
import ReactiveKit
import Nimble

/*
 # bindTo with an Operation.toStream passes value only once, but observeNext is called each time
 
 Strangely, the first time this code is ran, it works. However, the second time, no new value is seen on `calculatedLocationToCreateNewPlace: PushStream<CLLocation>`, which is bound to the output of the Operation.
 
 locationProvider.location(meterAccuracy: 5)
 .observeIn(Queue.background.context)
 .timeout(10, with: LocationProviderError.Timeout, on: Queue.main)
 .feedActivityInto(rightNavBarActivity)
 .toStream(feedErrorInto: locationError)
 .bindTo(calculatedLocationToCreateNewPlace)
 .disposeIn(bag) 
 
 However, if I instead replace the line `.bindTo(calculatedLocationToCreateNewPlace)` with the following:
 
 .observeNext {[weak self] location in
 self?.calculatedLocationToCreateNewPlace.next(location)
 }
 
 It receives a new value every time the Operation is called.
 */

class ProveOperationToStreamIssueTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    var bindedStream = PushStream<String>()
    func testBindedExample() {

        func callAndBindOperation(){
            operation()
                .toStream(justLogError: true)
                .bindTo(bindedStream)
                .disposeIn(rBag)
        }
        
        var timesValueChanged = 0
        bindedStream.observeNext {_ in
            timesValueChanged += 1
        }.disposeIn(rBag)
        
        
        // trigger the first time
        callAndBindOperation()
        
        // trigger the second time
        callAndBindOperation()
        
        expect(timesValueChanged).toEventually(equal(2))
    }
    
    var observedStream = PushStream<String>()
    func testObservedExample() {

        func callAndObserveOperation(){
            operation()
                .toStream(justLogError: true)
                .observeNext {[weak self] string in
                    self!.observedStream.next(string)
                }
                .disposeIn(rBag)
        }
        
        var timesValueChanged = 0
        observedStream.observeNext { string in
            timesValueChanged += 1
        }.disposeIn(rBag)
        
        // trigger the first time
        callAndObserveOperation()
        
        // trigger the second time
        callAndObserveOperation()
        
        expect(timesValueChanged).toEventually(equal(2))
    }
    
    private func operation()->Operation<String, NSError>{
        return Operation { observer in
            
            observer.next(NSUUID().UUIDString)
            
            return SimpleDisposable()
        }
    }

}
