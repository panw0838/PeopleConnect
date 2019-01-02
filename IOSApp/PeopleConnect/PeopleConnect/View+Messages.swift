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
        msgData.m_delegate = self
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
        cell.m_time.hidden = (cell.m_id < 10)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = msgData.m_conversations[indexPath.row]
        if conversation.m_id == ConvType.ConvRequest.rawValue {
            self.performSegueWithIdentifier("ShowRequests", sender: conversation)
        }
        else if conversation.m_id == ConvType.ConvPostNTF.rawValue {
            self.performSegueWithIdentifier("ShowNotify", sender: conversation)
        }
        else {
            self.performSegueWithIdentifier("ShowConversation", sender: conversation)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let conversation = sender as! Conversation
        if segue.identifier == "ShowRequests" {
            // sync new requests
            if conversation.m_messages.count > 0 || msgData.m_requests.count == 0 {
                msgData.UpdateRequests()
            }
            // clean notifications
            conversation.m_messages.removeAll()
        }
        if segue.identifier == "ShowNotify" {
            let to = segue.destinationViewController as! PostNotifyView
            to.m_data = conversation
        }
        if segue.identifier == "ShowConversation" {
            let to = segue.destinationViewController as! ConversationView
            to.m_conv = conversation
        }
    }
}