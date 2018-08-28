//
//  CoreDataService.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import Foundation
import CoreData

open class CoreDataService: ServiceProtocol {
    
    // MARK: - *** CoreDataService ***
    open static var sharedInstance: CoreDataService?
    
    // START CORE DATA SERVICE
    open static func start() {
        if  sharedInstance == nil {
            sharedInstance = CoreDataService()
        } else {
            print("ERROR: CoreDataService is trying to start 2 times")
        }
    }

    // STOP CORE DATA SERVICE
    open static func stop() {
        if sharedInstance != nil {
            sharedInstance?.saveContext()
            sharedInstance = nil
        }
    }

    // CHECK IF SERVICE IS RUNNING
    open static func isRunning() -> Bool {
        return sharedInstance != nil
    }
    
    open static func sharedManagedObjectContext() -> NSManagedObjectContext? {
        return sharedInstance?.managedObjectContext
    }

    // MARK: - *** PUBLIC ***
    
    open static func performOperationsAndSave(_ operationsClosure:@escaping (NSManagedObjectContext) -> Void, completionClosure:@escaping () -> Void) {
        sharedInstance?.performOperationsAndSave(operationsClosure, completionClosure: completionClosure)
    }
    
    // Delete all objects stored in Core Data
    open static func deleteAllObjectsInCoreData() {
        
        let allEntities = CoreDataService.sharedManagedObjectContext()?.persistentStoreCoordinator?.managedObjectModel.entities
        
        for entityDescription in allEntities! {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = entityDescription
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            
            let items: [AnyObject]?
            do {
                items = try CoreDataService.sharedManagedObjectContext()?.fetch(fetchRequest)
            } catch {
                print("Error requesting items from Core Data \(error.localizedDescription)")
                items = nil
            }
            
            for item in items! {
                CoreDataService.sharedManagedObjectContext()?.delete(item as! NSManagedObject)
            }
            
            do {
                try CoreDataService.sharedManagedObjectContext()?.save()
            } catch {
                print("Unresolved error \(error)")
            }
        }
    }
    
    // MARK: - *** PRIVATE ***
    fileprivate var coreDataQueue: DispatchQueue!
    
    fileprivate(set) lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    fileprivate init() {
        self.coreDataQueue = DispatchQueue(label: "Core.Data.Queue", attributes: [])
    }
    
    // The Documents URL where we are going to store files related to the app
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        
        // The directory the application uses to store the Core Data store file
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let baseUrl = urls[urls.count-1]
        let documentsUrl: URL = baseUrl.appendingPathComponent("OrangeB", isDirectory: true)
        let fileManager: FileManager = FileManager()
        
        var isDirectory: ObjCBool = false
        
        if !fileManager.fileExists(atPath: documentsUrl.path, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(at: documentsUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating store directory \(error.localizedDescription)")
            }
        }
        return documentsUrl
    }()
    
    fileprivate lazy var writerManagedObjectContext: NSManagedObjectContext? = {
        // Returns the writer object context for the application
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var writerManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        writerManagedObjectContext.persistentStoreCoordinator = coordinator
        return writerManagedObjectContext
    }()
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "OrangeB", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it
        // Create the coordinator and store
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationStoresDirectory()!.appendingPathComponent("OrangeB.sqlite")
        print("Core Data file is stored here \(url)")
        
        let options = [FileAttributeKey.protectionKey:FileProtectionType.complete]
        
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            print("Error adding persistent store \(error.localizedDescription)")
            
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

            
            let fm: FileManager = FileManager.default
            
            // Move Incompatible Store in case the Core Data model has been migrated to a new version
            if fm.fileExists(atPath: url.path) {
                let corruptURL: URL = self.applicationIncompatibleStoresDirectory()!.appendingPathComponent(self.nameForIncompatibleStore())
                
                // Move Corrupt Store
                do {
                    try fm.moveItem(at: url, to:corruptURL)
                } catch {
                    print("Error moving store \(error.localizedDescription)")
                }
            }
            
            do {
                try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
                UserDefaults.standard.set(true, forKey: "incompatibleStoreError")
                
            } catch  {
                coordinator = nil
            }
        }
        return coordinator
    }()
    
    // The Stores URL where we are going to store the Core Data file
    fileprivate func applicationStoresDirectory() -> URL? {
        let fm: FileManager = FileManager.default
        let applicationApplicationSupportDirectory: Foundation.URL = self.applicationDocumentsDirectory
        let URL = applicationApplicationSupportDirectory.appendingPathComponent("Stores")
        
        if !fm.fileExists(atPath: URL.path) {
            do {
                try fm.createDirectory(at: URL, withIntermediateDirectories:true, attributes:nil)
            } catch {
                print("Error creating Stores directory \(error.localizedDescription)")
            }
        }
        return URL
    }
    
    // The Stores URL where we are going to store old versions of the Core Data file
    fileprivate func applicationIncompatibleStoresDirectory() -> URL? {
        let fm: FileManager = FileManager.default
        let URL: Foundation.URL? = self.applicationStoresDirectory()?.appendingPathComponent("Incompatible")
        
        if !fm.fileExists(atPath: URL!.path) {
            do {
                try fm.createDirectory(at: URL!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Incompatible stores directory \(error.localizedDescription)")
            }
        }
        return URL
    }
    
    // Old incompatible stores will be saved in a different file
    fileprivate func nameForIncompatibleStore() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = DateFormatter.Behavior.behavior10_4
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let currentDate = dateFormatter.string(from: Date())
        return String(format: "%@.sqlite", arguments: [currentDate])
    }
    
    fileprivate func saveContext () {
        if let moc = self.writerManagedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch {
                    print("Error info: \(error)")
                }
            }
        }
    }
    
    // This method helps to perform taks in the managed object context and later save them
    fileprivate func performOperationsAndSave(_ operationsClosure:@escaping (NSManagedObjectContext) -> Void, completionClosure:@escaping () -> Void) {
        self.coreDataQueue.async(execute: {
            [weak self] in
            let temporaryContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            
            if let parent = self?.managedObjectContext {
                temporaryContext.parent = parent
                temporaryContext.performAndWait {
                    //perform all the database operations
                    operationsClosure(temporaryContext)
                    //save temporary context
                    do {
                        try temporaryContext.save()
                    } catch {
                        print("Unresolved temporaryContext error \(error)")
                    }
            
                    //perform synchonization between all contexts and write to disk
                    
                    if self != nil  {
                        self!.managedObjectContext?.performAndWait {
                            do {
                                try self!.managedObjectContext?.save()
                            } catch {
                                print("Unresolved managedObjectContext error \(error)")
                            }
                            
                            self!.writerManagedObjectContext?.performAndWait {
                                do {
                                    try self!.writerManagedObjectContext?.save() }
                                catch {
                                    print("Unresolved writerManagedObjectContext error \(error)")
                                }
                            }
                        }
                    }
                }
                completionClosure()
            }
        })
    }
}

