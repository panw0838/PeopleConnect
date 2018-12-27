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
    @IBOutlet weak var m_acceptBtn: UIButton!
    @IBOutlet weak var m_rejectBtn: UIButton!
    @IBOutlet weak var m_time: UILabel!
    
    var m_uid:UInt64 = 0
    
    @IBAction func AddContact(sender: AnyObject) {
        httpAddContact(m_uid, flag: UndefineBit, name: self.m_name.text!)
    }
    @IBAction func RemRequest(sender: AnyObject) {
        //httpRemRequest(m_uid)
    }
}

class MessegesView: UITableViewController, MsgDelegate {
    
    var m_selected:Int = 0
    
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
        let lastMsg = conversation.m_messeges.last!
        
        cell.m_messege.text = lastMsg.data
        cell.m_name.text = conversation.m_contact!.name
        cell.m_uid = conversation.m_contact!.user
        cell.m_profile.image = getPhoto(cell.m_uid)
        cell.m_profile.layer.cornerRadius = 10
        cell.m_acceptBtn.layer.cornerRadius = 10
        cell.m_rejectBtn.layer.cornerRadius = 10
        
        if lastMsg.type == .Request {
            cell.m_acceptBtn.hidden = false
            cell.m_rejectBtn.hidden = false
            cell.m_time.hidden = true
        }
        else {
            cell.m_acceptBtn.hidden = true
            cell.m_rejectBtn.hidden = true
            cell.m_time.hidden = false
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        m_selected = indexPath.row
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowConversation" {
            let to = segue.destinationViewController as! ConversationView
            to.m_conversastion = msgData.m_conversations[m_selected]
        }
    }
}