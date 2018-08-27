//
//  TransactionsDataProviderProtocol.swift
//  OrangeB
//
//  Created by Víctor Varillas on 24/8/18.
//  Copyright © 2018 VVL. All rights reserved.
//

import UIKit
import CoreData
import Foundation

public protocol TransactionsDataProviderProtocol: UITableViewDataSource {
    
    var tableView: UITableView! {get set}
    
    func transactionForIndexPath(_ indexPath: IndexPath) -> Transaction?
    func getNumberOfTransactions() -> Int
    func getTransactionsFromDatabase()
}

