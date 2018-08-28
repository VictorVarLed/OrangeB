//
//  TransactionsDataProvider.swift
//  OrangeB
//
//  Created by Víctor Varillas on 24/8/18.
//  Copyright © 2018 VVL. All rights reserved.
//

import UIKit
import CoreData
import Foundation

open class TransactionsDataProvider: NSObject, TransactionsDataProviderProtocol {
    
    open var managedObjectContext: NSManagedObjectContext?
    weak open var tableView: UITableView!
    
    var _fetchedResultsController: NSFetchedResultsController<Transaction>?
    
    // Get the transaction for a specific indexPath
    open func transactionForIndexPath(_ indexPath: IndexPath) -> Transaction? {
        return fetchedResultsController.object(at: indexPath)
    }
    
    // Get account balance
    public func getBalance() -> Float {
        var totalBalance:Float = 0.0
        
        for transaction in self.fetchedResultsController.fetchedObjects! {
            totalBalance = totalBalance + transaction.amount!.floatValue + transaction.fee!.floatValue
        }
        return totalBalance
    }
    
    // Get total number of transactions
    public func getNumberOfTransactions() -> Int {
        guard let numberOfTransactions = self.fetchedResultsController.fetchedObjects?.count else {
            return 0
        }
        return numberOfTransactions
    }
    
    // Fetch all the transactions from the database
    open func getTransactionsFromDatabase() {
        let sortDescriptor1 = NSSortDescriptor(key: "date", ascending: false)
        self.fetchedResultsController.fetchRequest.sortDescriptors = [sortDescriptor1]
        
        do {
            try fetchedResultsController.performFetch()
        }  catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
        tableView.reloadData()
    }
}

extension TransactionsDataProvider: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("txt_last_transaction",  comment: "Last transaction")
        } else if section == 2 {
            return NSLocalizedString("txt_previous_transactions",  comment: "Previous transactions")
        } else {
            return ""
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        guard let _ = self.fetchedResultsController.fetchedObjects?.count else {
            return 1
        }
        return 3
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            guard let numberOfTransactions = self.fetchedResultsController.fetchedObjects?.count else {
                return 0
            }
            if section == 1 {
                return 1
            } else if section == 2 {
                return numberOfTransactions - 1
            }
        } else {
            return 1
        }
        // Default
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell?
 
        // BALANCE CELL
        if indexPath.section == 0 {
            let balanceCell = tableView.dequeueReusableCell(withIdentifier: BalanceTableCell.uniqueIdentifier, for: indexPath) as! BalanceTableCell
            balanceCell.configureCell("IBAN ES91 2100 0418 4502 0005 1332", amount: self.getBalance())
            cell = balanceCell
            
        // LAST TRANSACTION CELL
        } else if indexPath.section == 1 {
            let index = IndexPath(row: 0, section: 0)
            let transaction:Transaction! = self.fetchedResultsController.object(at: index)
            let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableCell.uniqueIdentifier, for: indexPath) as! TransactionTableCell
            transactionCell.configureCell(transaction)
            cell = transactionCell
            
        // PREVIOUS TRANSACTIONS
        } else {
            let index = IndexPath(row: indexPath.row+1, section: 0)
            let transaction:Transaction! = self.fetchedResultsController.object(at: index)
            let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableCell.uniqueIdentifier, for: indexPath) as! TransactionTableCell
            transactionCell.configureCell(transaction)
            cell = transactionCell
        }
        
        return cell!
    }
}

extension TransactionsDataProvider: NSFetchedResultsControllerDelegate {
    
        var fetchedResultsController: NSFetchedResultsController<Transaction> {
        
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest<Transaction>()
        
        let entity = NSEntityDescription.entity(forEntityName: Transaction.getName(), in: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        let sortDescriptor1 = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor1]
        
        let newFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        newFetchedResultsController.delegate = self
        _fetchedResultsController = newFetchedResultsController
        
        do {
            try _fetchedResultsController?.performFetch()
        }  catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
        return _fetchedResultsController!
    }
    
    // If the NSFetchedResultsController changes the table should reload to show the changes
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
}
