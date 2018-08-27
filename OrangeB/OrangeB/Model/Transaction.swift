//
//  Transaction.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import Foundation
import CoreData

@objc(Transaction)
open class Transaction: NSManagedObject {
    
    @NSManaged var id: Int64
    @NSManaged var date: Date?
    @NSManaged var amount: NSNumber?
    @NSManaged var fee: NSNumber?
    @NSManaged var desc: String?
}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    // If the transaction ID is different then the transactions are completely different
    if lhs.id != rhs.id {
        return false
    }
    return true
}
