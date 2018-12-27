//
//  MessegeView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class MessegeCell: UITableViewCell {

    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_messege: UILabel!
    @IBOutlet weak var m_time: UILabel!
    
    var m_id:UInt64 = 0
}

class MessegesView: UITableViewController, MsgDelegate {

    func MsgUpdated() {
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msgData.m_delegates.append(self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgData.m_conversations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessegeCell") as! MessegeCell
        let conversation = msgData.m_conversations[indexPath.row]
        
        cell.m_messege.text = conversation.lastMessage()
        cell.m_name.text = conversation.m_name
        cell.m_id = conversation.m_id
        cell.m_profile.image = conversation.m_img
        cell.m_profile.layer.cornerRadius = 10
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = msgData.m_conversations[indexPath.row]
        if conversation.m_id == 0 {
            self.performSegueWithIdentifier("ShowRequests", sender: self)
        }
        else {
            self.performSegueWithIdentifier("ShowConversation", sender: conversation)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowRequests" {
            httpSyncRequests()
        }
        if segue.identifier == "ShowConversation" {
            let to = segue.destinationViewController as! ConversationView
            to.m_conversastion = (sender as! Conversation)
        }
    }
}