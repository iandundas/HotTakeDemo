//
//  Container.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 04/05/2016.
//  Copyright © 2016 IanDundas. All rights reserved.
//

import UIKit
import ReactiveKit

public class Container<ItemType: Equatable>{

    // Holds onto any subscriptions made. Is replaced when adding a new data source.
    private var disposable = DisposeBag()

    public var datasource: AnyDataSource<ItemType>{
        willSet{
            // we're getting rid of the current data source.
            // First we need to drop any observations on it:
            self.disposable.dispose()
        }
        didSet{

            // Now the data source is in place, we need to replace the items in our
            // collection with the new list of items in the new data source. Some of these
            // may be the same, so we want to perform a diff to identify any items that don't
            // need to be removed (or just need their list order to be updated)
            
            
            let incomingItems = datasource.items()
            let existingItems = collection.collection
            
            // Ensure that the incoming collection is different to the existing collection, because otherwise
            // we'll get an empty changeset event which can be mistaken for a .Initial event
            if incomingItems.elementsEqual(existingItems){
                // do nothing
            }
            else{
                collection.replace(incomingItems, performDiff: true)
            }
            setupDataSourceBinding()
        }
    }

    // This is the external, observable representation of the internal datasource.
    // When the data source mutates (or even if it is swapped), this will send valid ChangeSets
    public let collection: CollectionProperty<[ItemType]>

    public required init(datasource: AnyDataSource<ItemType>){ // , rebinding: RebindingType){

        self.datasource = datasource

        let existingItems = datasource.items()

        collection = CollectionProperty(existingItems)

        setupDataSourceBinding()
    }

    private func setupDataSourceBinding(){
        datasource.mutations()
            .filter{ !$0.hasNoMutations } // we set the initial value manually when binding, so this causes a duplicate event, filter it out.
            .bindTo(collection)
            .disposeIn(disposable)
    }

    deinit{
        disposable.dispose()
    }
}
