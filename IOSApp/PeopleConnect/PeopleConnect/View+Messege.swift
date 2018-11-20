//
//  MessegeView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class ReceiveCell: UITableViewCell {
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_messege: UILabel!
    
}

class SendCell: UITableViewCell {
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_messege: UILabel!
    
}

class MessegeView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var m_id:UInt64 = 0
    var m_conversastion:Conversation? = nil
    
    @IBOutlet weak var m_text: UITextField!
    
    @IBAction func SendMessege(sender: AnyObject) {
        let messege = m_text.text
        if messege?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            httpSendMessege(m_id, messege: messege!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        m_conversastion = messegeData.GetConversation(m_id)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_conversastion!.m_messeges.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let messege = m_conversastion!.m_messeges[indexPath.row]
        if messege.from == userInfo.userID {
            let cell = tableView.dequeueReusableCellWithIdentifier("MessegeSent") as! SendCell
            cell.m_messege.text = messege.data
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("MessegeReceive") as! ReceiveCell
            cell.m_messege.text = messege.data
            return cell
        }
    }
}
