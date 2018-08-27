//
//  BalanceTableCell.swift
//  OrangeB
//
//  Created by Víctor Varillas on 26/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import UIKit
import CoreData
import Foundation

open class BalanceTableCell: UITableViewCell
{
    // MARK: - *** Public ***
    open static var uniqueIdentifier:String = "BalanceTableCell"
    
    internal func configureCell(_ iban:String, amount: Float) {
        
        //configure the IBAN string label
        self.ibanNumberLabel.text = iban

        //configure the balance amount label
        let font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.light)
        let textAttributes:[NSAttributedStringKey : Any]? = [NSAttributedStringKey.font:font]
        let finalAmount:String = NSLocalizedString("txt_balance", comment: "Balance") + String(amount)
        let attributedText:NSAttributedString = NSAttributedString(string: finalAmount + " €", attributes:textAttributes)
        self.balanceAmountLabel.attributedText = attributedText
    }
    
    
    // MARK: - *** Private ***
    
    @IBOutlet weak fileprivate var ibanNumberLabel: UILabel!
    @IBOutlet weak fileprivate var balanceAmountLabel: UILabel!
}
