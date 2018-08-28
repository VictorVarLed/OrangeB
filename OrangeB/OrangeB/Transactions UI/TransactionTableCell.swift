//
//  TransactionsTableCell.swift
//  OrangeB
//
//  Created by Víctor Varillas on 26/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import UIKit
import CoreData
import Foundation

open class TransactionTableCell: UITableViewCell {
    // MARK: - *** Public ***
    open static var uniqueIdentifier:String = "TransactionTableCell"
    
    internal func configureCell( _ transaction : Transaction! ) {
        self.transaction = transaction
        
        // Transaction date
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy" //2018-07-26T19:26:10.000Z
        
        if transaction.date != nil {
            self.transactionDateLabel.text = dateFormatter.string(from: transaction.date!)
        }
        
        // Currency formatter to use the current locale
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        
        if transaction.fee != nil {
            self.transactionFeeLabel.text = NSLocalizedString("txt_fee_text", comment: "Fee") + currencyFormatter.string(from: transaction.fee!)!
        }
        
        if transaction.amount != nil {
            // For the total amount we have to substract the fee from the original quantity
            let totalAmount = transaction.amount!.floatValue + transaction.fee!.floatValue
            let amountString = currencyFormatter.string(from: NSNumber(value: totalAmount))!
            self.transactionAmountLabel.text = amountString
            
            if totalAmount < 0 {
                self.transactionAmountLabel.textColor = UIColor.red
            } else {
                self.transactionAmountLabel.textColor = UIColor.green
            }
        }
        self.transactionDescriptionLabel.text = transaction.desc
    }
    
    
    // MARK: - *** Private ***
    fileprivate weak var transaction:Transaction!
    
    @IBOutlet weak fileprivate var transactionDateLabel: UILabel!
    @IBOutlet weak fileprivate var transactionDescriptionLabel: UILabel!
    @IBOutlet weak fileprivate var transactionFeeLabel: UILabel!
    @IBOutlet weak fileprivate var transactionAmountLabel: UILabel!
}
