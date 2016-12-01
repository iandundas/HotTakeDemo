//
//  ViewController.swift
//  ReactiveKitSwappableDatasource
//
//  Created by Ian Dundas on 05/15/2016.
//  Copyright (c) 2016 Ian Dundas. All rights reserved.
//

import UIKit
import ReactiveUIKit
import ReactiveKit
import RealmSwift
import HotTakeCore
import HotTakeRealm

enum DemoDataSourceType{
    
    case Manual, Realm
    
    var datasource: AnyDataSource<Cat> {
        
        switch self {
        case Manual:
            let collection = [
                Cat(value: ["name" : "Mr Timpy", "miceEaten": 8]),
                Cat(value: ["name" : "Tumpy", "miceEaten": 3]),
                Cat(value: ["name" : "Whiskers", "miceEaten": 30]),
                Cat(value: ["name" : "Meow Now", "miceEaten": 10]), ]
            
            return AnyDataSource(ManualDataSource<Cat>(items: collection))
            
        case .Realm:
            let realm = try! RealmSwift.Realm(configuration: RealmSwift.Realm.Configuration(inMemoryIdentifier: "MyInMemoryRealm"))
            let result = realm.objects(Cat).sorted("miceEaten")

            return AnyDataSource(RealmDataSource(items: result))
        }
    }
    
}

class ViewController: UITableViewController {
    
    let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "MyInMemoryRealm"))
    
    var datasourceContainer:HotTakeCore.Container<Cat>!
    
    var datasourceType = DemoDataSourceType.Manual
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let datasource = datasourceType.datasource

        datasourceContainer = HotTakeCore.Container(datasource: datasource)
        datasourceContainer.collection.bindTo(tableView) {
            (indexPath, items, tableView) -> UITableViewCell in
            
            let item = items[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = item.name
            return cell
            
        }.disposeIn(rBag)
    }
    
    
    // MARK: Actions:
    
    // Insert a cat into realm
    @IBAction func tappedA(sender: AnyObject) {
        let cat = Cat(value: ["name" : "Mr Timpy", "miceEaten": 8])
        
        try! realm.write {
            realm.add(cat, update: true)
        }
    }
    
    // Change to another data source
    @IBAction func tappedB(sender: AnyObject) {
    
        switch (datasourceType){
        case .Manual:
            datasourceType = .Realm
        case .Realm:
            datasourceType = .Manual
        }
        
        datasourceContainer.datasource = datasourceType.datasource
    }
}
