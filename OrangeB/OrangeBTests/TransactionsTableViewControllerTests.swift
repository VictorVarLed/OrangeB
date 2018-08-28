//
//  TransactionsTableViewControllerTests.swift
//  OrangeBTests
//
//  Created by Víctor Varillas on 28/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import Foundation

import XCTest
@testable import OrangeB

class UITransactionsTableViewControllerTests: XCTestCase {
    
    var systemUnderTest: TransactionsTableViewController!
    
    override func setUp() {
        super.setUp()
        
        // Get the storyboard. The view controller under test is inside
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Get the View Controller we want to test from the Storyboard
        systemUnderTest = storyboard.instantiateViewController(withIdentifier: "TransactionsTableViewController") as! TransactionsTableViewController
        
        systemUnderTest.dataProvider = TransactionsDataProvider()
        
        // Load view hierarchy
        _ = systemUnderTest.view
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSUT_TableViewIsNotNilAfterViewDidLoad() {
        
        XCTAssertNotNil(systemUnderTest.tableView)
    }
    
    func testSUT_ShouldSetTableViewDataSource() {
        
        XCTAssertNotNil(systemUnderTest.tableView.dataSource)
    }
    
    func testSUT_ShouldSetTableViewDelegate() {
        
        XCTAssertNotNil(systemUnderTest.tableView.dataSource)
    }
    
    func testSUT_ConformsToTableViewDataSourceProtocol() {
        
        XCTAssert(systemUnderTest.dataProvider!.conforms(to: UITableViewDataSource.self))
        
        XCTAssert(systemUnderTest.dataProvider!.responds(to: #selector(systemUnderTest.dataProvider?.numberOfSections(in:))))
        
        XCTAssert(systemUnderTest.dataProvider!.responds(to: #selector(systemUnderTest.dataProvider!.tableView(_:numberOfRowsInSection:))))
        
        XCTAssert(systemUnderTest.dataProvider!.responds(to: #selector(systemUnderTest.dataProvider!.tableView(_:cellForRowAt:))))
    }
    
    func testSUT_ConformsToTableViewDelegateProtocol() {
        
        XCTAssert(systemUnderTest.conforms(to: UITableViewDelegate.self))
        
        XCTAssert(systemUnderTest.responds(to: #selector(systemUnderTest.tableView(_:didSelectRowAt:))))
    }
    
}
