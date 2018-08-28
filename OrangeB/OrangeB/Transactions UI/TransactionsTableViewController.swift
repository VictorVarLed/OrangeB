//
//  ViewController.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class TransactionsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: *** Public ***

    open var dataProvider: TransactionsDataProvider?

    override open func viewDidLoad() {

        super.viewDidLoad()

        // Set activity indicator
        self.setActivityIndicator()

        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        self.tableView.tableHeaderView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.delegate = self

        // If there is no Internet connection
        if ReachabilityService.currentReachabilityStatus == ReachabilityService.NetworkStatus.notReachable {
            self.showNoInternetConnection()
            
        // If there is Internet connection
        } else {
            TransactionManagerService.fetchAndUpdateTransactions {
                print("Fetch completed")
                
                DispatchQueue.main.async(execute: {
                    self.dataProvider = TransactionsDataProvider()
                    self.dataProvider?.managedObjectContext = self.managedObjectContext
                    
                    assert(self.dataProvider != nil, "dataProvider is not allowed to be nil at this point")
                    self.tableView.dataSource = self.dataProvider
                    self.dataProvider?.tableView = self.tableView

                    self.dataProvider?.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                })
            }
        }
    }
    
    // MARK: - *** Private ***

    fileprivate lazy var managedObjectContext: NSManagedObjectContext = CoreDataService.sharedManagedObjectContext()!
    fileprivate var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) as UIActivityIndicatorView
    
    private func setActivityIndicator(){
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 50)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        self.tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func showNoInternetConnection() {
        let alert = UIAlertController(title: NSLocalizedString("txt_no_internet", comment: "No internet connection"), message: NSLocalizedString("txt_cannot_get_latest_transactions", comment: "Unable to get transactions"), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("txt_OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: {_ in}))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - *** TableView Delegate

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 120
        } else {
            return 80
        }
    }

    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 60
        }
        return 0
    }
}
