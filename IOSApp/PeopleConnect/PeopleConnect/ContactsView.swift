//
//  ContactsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import PagingMenuController

class ContactsView: UITableViewController {
    // main tags
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return userData.numMainTags()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    //override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    //    let cell = tab
    //}
}