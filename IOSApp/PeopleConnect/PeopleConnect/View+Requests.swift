//
//  View+Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/12/28.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

class RequestCell:UITableViewCell {
    @IBOutlet weak var m_photo: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_message: UILabel!
    @IBOutlet weak var m_acceptBtn: UIButton!
    @IBOutlet weak var m_rejectBtn: UIButton!
    
    var m_uid:UInt64 = 0
    
    @IBAction func accept(sender:AnyObject) {
        //httpAddContact(m_uid, name: "")
    }
    
    @IBAction func reject(sender:AnyObject) {
        // to do
    }
}

class RequestsView:UIViewController, MsgDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_table: UITableView!
    
    func MsgUpdated() {
        m_table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msgData.m_requestDelegate = self
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
        cell.m_uid = request.from
        cell.m_name.text = contact?.name
        cell.m_photo.image = getPhoto(cell.m_uid)
        cell.m_message.text = request.messege
        return cell
    }
}
