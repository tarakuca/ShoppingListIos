//
//  AppDelegate.swift
//  Shopping List
//
//  Created by Mirza Irwan on 1/7/17.
//  Copyright © 2017 Mirza Irwan <mirza.irwan.osman@gmail.com>. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = window!.rootViewController as! UISplitViewController
        
        let navigationController = splitViewController.viewControllers[1] as! UINavigationController
        
        //The following will enable ONLY iPhone 7+ Landscape to have the "expand button" on its detail vc when it is NOT displayed via a segue from master
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        loadDummyShoppingList()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Shopping_List")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    //For convenience
    static var persistentContainer: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - For testing only
    func loadDummyShoppingList() {
        
        let groceryShoppingList = ShoppingList.findOrCreateNew(name: "Grocery", context: persistentContainer.viewContext)
        if (groceryShoppingList?.objectID.isTemporaryID)! {
            //New shopping liat
            groceryShoppingList?.name = "Grocery"
            groceryShoppingList?.comments = "Everyday stuffs"
            groceryShoppingList?.lastUpdatedOn = NSDate()
            
            do {
                let banana = try Item.findOrCreateNewItem(name: "Banana", context: persistentContainer.viewContext)
                banana.name = "Banana"
                banana.brand = "Del Monte"
                
                let milk = try Item.findOrCreateNewItem(name: "Milk", context: persistentContainer.viewContext)
                milk.name = "Milk"
                milk.brand = "Magnolia"
                
                let fruit = try Item.findOrCreateNewItem(name: "Australian Watermelon", context: persistentContainer.viewContext)
                
                fruit.name = "Australian Watermelon"
                fruit.brand = "Australian Farm for Watermelon"
                
                _ = groceryShoppingList?.add(item: banana, quantity: 5)
                _ = groceryShoppingList?.add(item: milk, quantity: 4)
                _ = groceryShoppingList?.add(item: fruit, quantity: 599)
                
                
            } catch {
                let nserror = error as NSError
                print("Error occured \(nserror): \(nserror.userInfo)")
            }
        }
        
        let artShoppingList = ShoppingList.findOrCreateNew(name: "Art project", context: persistentContainer.viewContext)
        if (artShoppingList?.objectID.isTemporaryID)! {
            //New shopping liat
            artShoppingList?.name = "Art project"
            artShoppingList?.comments = "For NAFA"
            artShoppingList?.lastUpdatedOn = NSDate()
        }
        
        saveContext()
        
    }
    
    // MARK: - Collapsing and Expanding the interface
    
    //Called by iPhone 7+ Potrait, iPhone 7 (Potrait & Landscape)
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        
        guard let secondaryAsNc = secondaryViewController as? UINavigationController else { return false }
        guard let rootVcOfNc = secondaryAsNc.visibleViewController as? ShoppingListTableViewController else { return false }
        if rootVcOfNc.shoppingList == nil {
            return true
        }
        return false
    }
    
}

