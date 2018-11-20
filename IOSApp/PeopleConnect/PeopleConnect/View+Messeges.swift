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

class MessegesView: UITableViewController, MessegeRequestCallback {
    
    func MessegeUpdateUI() {
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messegeCallbacks.append(self)
        httpSyncMessege()
        httpSyncRequests()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messegeData.m_conversations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessegeCell") as! MessegeCell
        let conversation = messegeData.m_conversations[indexPath.row]
        cell.m_messege.text = (conversation.lastMessege() == nil ? "" : conversation.lastMessege())
        cell.m_name.text = conversation.m_contact.name
        cell.m_uid = conversation.m_contact.user
        return cell
    }
}