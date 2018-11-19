//
//  MessegeView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class MessegeCell: UITableViewCell {
    @IBOutlet weak var m_profile: UIView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_messege: UILabel!
    @IBOutlet weak var m_accept: UIButton!
    
    var m_uid:UInt64 = 0
    
    @IBAction func AddContact(sender: AnyObject) {
        httpAddContact(m_uid, flag: 2, name: "kkkk")
    }
}

class MessegesView: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        httpSyncMessege()
        httpSyncRequests()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messegeData.m_senders.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessegeCell") as! MessegeCell
        let sender = messegeData.m_senders[indexPath.row]
        cell.m_messege.text = (sender.lastMessege() == nil ? "" : sender.lastMessege())
        cell.m_name.text = sender.m_contact.name
        cell.m_uid = sender.m_contact.user
        return cell
    }
}