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
    @IBOutlet weak var m_messege: UILabel!
    
}

class SendCell: UITableViewCell {
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_messege: UILabel!
    
}

class MessegeView: UIViewController, UITableViewDataSource, UITableViewDelegate, MessegeRequestCallback {
    
    var m_conversastion:Conversation? = nil
    
    @IBOutlet weak var m_text: UITextField!
    @IBOutlet weak var m_messegesTable: UITableView!
    
    @IBAction func SendMessege(sender: AnyObject) {
        let messege = m_text.text
        if messege?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            //httpSendMessege(m_conversastion!.m_id, messege: messege!)
            tcp.sendMessege(m_conversastion!.m_id, messege: messege!)
        }
    }
    
    func MessegeUpdateUI() {
        self.m_messegesTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messegeCallbacks.append(self)
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
