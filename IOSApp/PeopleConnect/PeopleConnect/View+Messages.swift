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
    @IBOutlet weak var m_alert: UIImageView!
    
    var m_conv:Conversation?
    
    func reload(conv:Conversation) {
        m_conv = conv
        let last = conv.m_messages.last
        
        self.m_messege.text = conv.lastMessage()
        self.m_name.text = conv.m_name
        self.m_profile.image = conv.m_img
        self.m_profile.layer.cornerRadius = 10
        self.m_profile.layer.masksToBounds = true
        self.m_time.hidden = (conv.m_id < 10)
        self.m_time.text = (last == nil ? "" : getTimeString(last!.time))
        self.m_alert.hidden = !m_conv!.m_newMsg
    }
}

class MessegesView: UITableViewController, MsgDelegate {

    func MsgUpdated() {
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msgData.m_delegate = self
        httpSyncMessege(nil, failed: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgData.m_conversations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessegeCell") as! MessegeCell
        let index = msgData.m_conversations.count - 1 - indexPath.row
        let conv = msgData.m_conversations[index]

        cell.reload(conv)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MessegeCell
        if cell.m_conv!.m_id == ConvType.ConvRequest.rawValue {
            self.performSegueWithIdentifier("ShowRequests", sender: cell.m_conv!)
        }
        else if cell.m_conv!.m_id == ConvType.ConvPostNTF.rawValue {
            self.performSegueWithIdentifier("ShowNotify", sender: cell.m_conv!)
        }
        else {
            self.performSegueWithIdentifier("ShowConversation", sender: cell.m_conv!)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let conversation = sender as! Conversation
        conversation.m_newMsg = false
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