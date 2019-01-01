//
//  View+PostNotifies.swift
//  PeopleConnect
//
//  Created by apple on 19/1/1.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class PostNotifyCell:UITableViewCell {
    
}


class PostNotifyView:UIViewController, MsgDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_table: UITableView!
    
    var m_data:Conversation?
    
    func MsgUpdated() {
        m_table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgData.m_requests.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RequestCell") as! RequestCell
        let request = msgData.m_requests[indexPath.row]
        let contact = contactsData.m_contacts[request.from]
        return cell
    }
}