//
//  RealmDataSource.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit
import ReactiveKit
import RealmSwift
import HotTakeCore

extension AnyRealmCollection{
    func items()-> [Element]{
        return filter{_ in true}
    }
}

public class RealmDataSource<Item: Object where Item: Equatable>: DataSourceType {

    /* NB: It's important that the Realm collection is already sorted before it's passed to the RealmDataSource:

     > "Note that the order of Results is only guaranteed to stay consistent when the
     > query is sorted. For performance reasons, insertion order is not guaranteed to be preserved.
     > If you need to maintain order of insertion, some solutions are proposed here.
     */

    public func items() -> [Item] {
        return self.collection.items()
    }

    public func mutations() -> Stream<CollectionChangeset<[Item]>> {
        return Stream<CollectionChangeset<[Item]>> { observer in
            let bag = DisposeBag()
            
            var initialChangeSet: CollectionChangeset? = CollectionChangeset.initial(self.items())
            observer.next(initialChangeSet!)
            
            let notificationToken = self.collection.addNotificationBlock {(changes: RealmCollectionChange) in

                switch changes {
                case .Initial(let initialCollection):
                    
                    if let initialItems = initialChangeSet?.collection {
                        initialChangeSet = nil
                        
                        // Realm .initial event clashes with our own. Need to work out if it's any different to the
                        // event we sent observers when they first observed
                        if initialCollection.elementsEqual(initialItems){
                            // If it's the same we want to suppress it totally
                            break;
                        }
                        else{
                            // If it's different, we need to manually diff Realm's .initial with our own
                            // and provide that diff as the real initial event.
                            let tempCollection = CollectionProperty(initialItems)
                            
                            tempCollection.skip(1).observeNext(observer.next).disposeIn(bag)
                            tempCollection.replace(initialCollection.items(), performDiff: true)
                            break;
                        }
                    }
                    else {
                        let insertIndexes = (initialCollection.startIndex ..< initialCollection.endIndex).map {$0}
                        let changeSet = CollectionChangeset(collection: initialCollection.items(), inserts: insertIndexes, deletes: [], updates: [])
                        observer.next(changeSet)
                    }
                    
                case .Update(let updatedCollection, let deletions, let insertions, let modifications):
                    let changeSet = CollectionChangeset(collection: updatedCollection.items(), inserts: insertions, deletes: deletions, updates: modifications)
                    observer.next(changeSet)

                case .Error(let error):

                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError("\(error)")
                    break
                }
            }
            
            
            bag.addDisposable(BlockDisposable{
                notificationToken.stop()
            })
            return bag
        }
    }

    private let collection: AnyRealmCollection<Item>

    private let disposeBag = DisposeBag()

    public init<C: RealmCollectionType where C.Element == Item>(items: C) {
        self.collection = AnyRealmCollection(items)
    }
}
