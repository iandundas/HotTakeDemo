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


let sharedRealmID = "MyInMemoryRealm"

enum DemoDataSourceType{
    
    case Manual(cats: [Cat])
    case Realm
    
    var datasource: AnyDataSource<Cat> {
        
        switch self {
        case Manual(let cats):
            return ManualDataSource<Cat>(items: cats).eraseType()
            
        case .Realm:
            let realm = try! RealmSwift.Realm(configuration: RealmSwift.Realm.Configuration(inMemoryIdentifier: sharedRealmID))
            let result = realm.objects(Cat).sorted("miceEaten")
            return RealmDataSource(items: result).eraseType()
        }
    }
    
    var title: String{
        switch self{
        case .Manual: return "Array"
        case .Realm: return "Realm"
        }
    }
    
}

class ViewController: UITableViewController {
    
    // Create an in-memory realm:
    let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: sharedRealmID))
    
    var datasourceType: DemoDataSourceType!{
        didSet{
            title = datasourceType.title
            container.datasource = datasourceType.datasource
        }
    }
    
    var container:HotTakeCore.Container<Cat>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        
        let initialDataSourceType = DemoDataSourceType.Manual(cats: self.manual)
        container = HotTakeCore.Container(datasource: initialDataSourceType.datasource)
        datasourceType = initialDataSourceType
        
        container.collection.observeNext { (changeset) in
            print("Changeset: \(changeset)\n\n")
        }.disposeIn(rBag)
        
        // Bind to TableView:
        container.collection.bindTo(tableView) {
            (indexPath, items, tableView) -> UITableViewCell in
            
            let item = items[indexPath.row]
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = item.name
            return cell
            
        }.disposeIn(rBag)
        
        
        let catNames = ["Ali Cat", "Mr Paws", "Ali McClaw", "Tumpy", "Angelicat", "Kitten X", "Cat Benatar", "Catalie Portman", "Catsy Cline", "Chairwoman Miao", "Cindy Clawford", "Clawdia", "Demi Meower", "Empress", "Fleas Witherspoon", "Halley Purry", "Hello Kitty", "Isabellick", "Katy Purry"]
        zip(tappedInsertCat, Stream.sequence(catNames)).observeNext { [weak self] _, catName in
            guard let realm = self?.realm else {return}
        
            try! realm.write {
                let cat = Cat(value: ["name" : catName, "miceEaten": Int(arc4random_uniform(200) + 1)])
                realm.add(cat, update: true)
            }
        }.disposeIn(rBag)
    }
    
    // Pull a random set of cats (name containing "cat") from Realm, store in an array:
    var manual:[Cat]{   
        let query = realm.objects(Cat).sorted("miceEaten").filter("name CONTAINS[c] %@", "cat")
        return query.filter {_ in true }
    }
    
    
    // MARK: Actions:
    
    let tappedInsertCat = PushStream<Void>()
    @IBAction func insertCat(sender: AnyObject) {
        tappedInsertCat.next()
    }
    
    @IBAction func useArray(sender: AnyObject) {
        datasourceType = .Manual(cats: self.manual)
    }
    
    @IBAction func useRealm(sender: AnyObject) {
        datasourceType = .Realm
    }
    
}
