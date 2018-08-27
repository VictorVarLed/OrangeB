//
//  TransactionManagerService.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import Foundation
import CoreData

open class TransactionManagerService {
    
    // MARK: - *** public ***

    open static func fetchAndUpdateTransactions(_ completionClosure:@escaping () -> Void) {

        let restPoint = "/1a30k8"
        TransactionManagerService.makeRestCall(RestService.HTTPMethods.GET, restPoint: restPoint, completionClosure: {
            
            json, error in
            print("Response received \(String(describing: json))")
            
            CoreDataService.deleteAllObjectsInCoreData()
            
            CoreDataService.performOperationsAndSave({
                context in
                
                let transactionsDic:[NSDictionary]! = json == nil ? nil : json as! [NSDictionary]
                
                // Update or inserts new fields
                if transactionsDic != nil {
                    
                    let entity =  NSEntityDescription.entity(forEntityName: Transaction.getName(), in:context)

                    for transactionItem:NSDictionary in transactionsDic { // We are going to iterate over all the transactions received
                        
                        // Transaction date formatter
                        let dateFormatter:DateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sssZ" //2018-07-26T19:26:10.000Z
                        
                        // If we have a date but it is NOT valid then skip this transaction
                        if transactionItem["date"]  != nil {
                            guard dateFormatter.date(from: (transactionItem["date"] as? String)!) != nil else {
                                continue
                            }
                        }
                        
                        // We have to check that there is no existing transaction with the same ID and newer date
                        let transactionID = transactionItem["id"] as! Int64
                        let transactionDate = dateFormatter.date(from: (transactionItem["date"] as? String)!)!
                        self.checkIfIDExistsWithNewerDate(transactionID, date:transactionDate, completionClosure:{})

                        let transaction = Transaction(entity: entity!, insertInto: context)
                        transaction.id = transactionID

                        // Save the transaction date
                        if transactionItem["date"]  != nil {
                            transaction.date = transactionDate
                        }
                        
                        // Save the transaction amount
                        if transactionItem["amount"] != nil {
                            transaction.amount = transactionItem["amount"] as? NSNumber
                        }

                        // Save the transaction fee
                        if transactionItem["fee"] != nil {
                            transaction.fee = transactionItem["fee"] as? NSNumber
                        }
                        
                        // Save the transaction description
                        if transactionItem["description"]  != nil {
                            transaction.desc = transactionItem["description"] as? String
                        }
                        do {
                            try context.save()
                        } catch {
                            print("Unresolved error \(error)")
                        }
                    }
                }                
            }, completionClosure: {
                completionClosure()
            })
        })
    }
    
    // This function receives an ID and a date and check if it should delete and old transaction with equal ID
    open static func checkIfIDExistsWithNewerDate(_ idNumber:Int64, date:Date, completionClosure:@escaping () -> Void) {
        
        CoreDataService.performOperationsAndSave({
            context in

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Transaction.getName())
            var resultsArr:[Transaction] = []
            do {
                resultsArr = try (context.fetch(fetchRequest) as! [Transaction])
            } catch {
                print(error)
            }
            
            if resultsArr.count > 0 {
                for x in resultsArr {
                    if x.id == idNumber && x.date! < date {
                        context.delete(x)
                    }
                }
            }
        }, completionClosure: {
            completionClosure()
        })
    }
    
    // MARK: - *** private ***
    fileprivate static func makeRestCall( _ method: RestService.HTTPMethods, restPoint: String, completionClosure:@escaping (_ json: AnyObject?, _ error: NSError?) -> Void ) {
        
        RestService.makeRestCall(method, restPoint: restPoint, completionClosure: {
            data, response, error in
            
            if  response != nil && error == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200 {
                        let json:Any! = (data == nil || data!.count == 0) ? nil : (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers))
                        completionClosure(json as AnyObject?, nil)
                        return
                        
                    } else {
                        let errorInfo = NSError(domain: "Rest call error", code: 123, userInfo: nil)
                        completionClosure(nil, errorInfo)
                        return
                    }
                }
            }
            completionClosure(nil, error as NSError?)
        })
    }
}
