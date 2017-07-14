//
//  ShoppingListTableViewController.swift
//  Shopping List
//
//  Created by Mirza Irwan on 1/7/17.
//  Copyright © 2017 Mirza Irwan <mirza.irwan.osman@gmail.com>. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListTableViewController: FetchedResultsTableViewController {
    
    // MARK : - API
    
    /**
     Public API.
     Display all the items in the shopping list
    */
    var shoppingList: ShoppingList? {
        didSet {
            print("\(#function) - \(type(of: self))")
            updateUi()
        }
    }
    
    // MARK : - Properties
    var persistentContainer: NSPersistentContainer = AppDelegate.persistentContainer
    
    // Mark: - Model
    var fetchedResultsController: NSFetchedResultsController<ShoppingListItem>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //The following does not work because viewWillAppear is not called when using popover. My solution is use an unwind segue and manually clear the cell selection
        clearsSelectionOnViewWillAppear = true
        
        navigationItem.title = shoppingList?.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("\(#function) - \(type(of: self))")
        super.viewWillAppear(animated)
    }
    
    func updateUi() {
        fetchItemsInShoppingList()
    }
    
    func fetchItemsInShoppingList() {
        
        guard let shoppingList = self.shoppingList else { return }
        
        //Request items in shopping list
        let requestForShoppingListItem: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        
        //Matching criteria
        let criteria = NSPredicate(format: "shoppingList = %@", shoppingList)
        requestForShoppingListItem.predicate = criteria
        
        //Sort by
        let sortBy = [NSSortDescriptor(key: "item.name", ascending: true)]
        requestForShoppingListItem.sortDescriptors = sortBy
        
        //Go fetch
        fetchedResultsController = NSFetchedResultsController(fetchRequest: requestForShoppingListItem,
                                                              managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil,
                                                              cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch  {
            let nserror = error as NSError
            print("Error \(nserror) occured: \(nserror.userInfo)")
        }
        
    }
    
    // MARK: - Table view data source II
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let shoppingListItemCell = tableView.dequeueReusableCell(withIdentifier: "Shopping List Item", for: indexPath) as! ShoppingListItemTableViewCell
        
        // Configure the cell...
        let shoppingListItem = fetchedResultsController?.object(at: indexPath)
        
        shoppingListItemCell.shoppingListItem = shoppingListItem
        
        return shoppingListItemCell
    }
    
    // MARK: - Navigation
    
    //Do create an shopping list item when a shopping list exist
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if shoppingList != nil {
            return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        } else {
            return false
        }
    }
    
    @IBAction func unwindToShoppingList(for segue: UIStoryboardSegue) {
        
        print(">>> \(#function) - \(type(of: self))")
        
        //viewWillAppear is not called when using popover. My solution is use an unwind segue and manually clear the cell selection
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        var destinationVc = segue.destination
        
        if let navigationController = destinationVc as? UINavigationController {
            
            destinationVc = navigationController.visibleViewController!
        }
        
        if let id = segue.identifier, id == "Update Shopping List Item" {
            
            let shoppingEditorVc = destinationVc as! ShoppingListItemEditorViewController
            
            shoppingEditorVc.shoppingList = shoppingList
            
            let cell = sender as! ShoppingListItemTableViewCell
            
            let indexPath = tableView.indexPath(for: cell)!
            
            let shoppingListItem = fetchedResultsController?.object(at: indexPath)
            
            shoppingEditorVc.shoppingListItem = shoppingListItem
            
        }
        
        if let id = segue.identifier, id == "New Shopping List Item" {
            
            let shoppingEditorVc = destinationVc as! ShoppingListItemEditorViewController
            
            shoppingEditorVc.shoppingList = shoppingList
        }
        
        if let id = segue.identifier, id == "item detail" {
            
            let itemDetailVc = destinationVc as! ItemDetailViewController
            
            itemDetailVc.shoppingListItem = selectedShoppingListItem
        }
    }
    
    var selectedShoppingListItem: ShoppingListItem? {
        let indexOfSelectedShoppingListItem = tableView.indexPathForSelectedRow
        if let indexPathSelected = indexOfSelectedShoppingListItem {
            return fetchedResultsController?.object(at: indexPathSelected)
        } else {
            return nil
        }
    }
}

extension ShoppingListTableViewController {
    
    // MARK: - Table view data source I
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }
    
}



















