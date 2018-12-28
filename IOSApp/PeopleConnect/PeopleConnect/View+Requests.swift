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
    @IBOutlet weak var m_photoBtn: UIButton!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_message: UILabel!
    @IBOutlet weak var m_acceptBtn: UIButton!
    @IBOutlet weak var m_rejectBtn: UIButton!
    
    var m_uid:UInt64 = 0
    var m_father:UIViewController?
    
    @IBAction func showContact(sender:AnyObject) {
        ContactView.ContactID = m_uid
        httpSyncContactPost(m_uid)
        m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
    }
    
    func nameChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }
    
    @IBAction func accept(sender:AnyObject) {
        let alert = UIAlertController(title: "通过好友申请", message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Destructive,
            handler: { action in
                httpAddContact(self.m_uid, name: (alert.textFields?.first?.text)!)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "好友备注"
            textField.addTarget(self, action: Selector("nameChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        m_father?.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func reject(sender:AnyObject) {
        let alert = UIAlertController(title: "拒绝好友申请", message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Destructive,
            handler: { action in
                httpDeclineRequest(self.m_uid)
        })
        alert.addAction(noAction)
        alert.addAction(okAction)
        m_father?.presentViewController(alert, animated: true, completion: nil)
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
        cell.m_photoBtn.setImage(getPhoto(cell.m_uid), forState: .Normal)
        cell.m_message.text = request.messege
        cell.m_father = self
        cell.m_photoBtn.layer.cornerRadius = 10
        cell.m_acceptBtn.layer.cornerRadius = 10
        cell.m_rejectBtn.layer.cornerRadius = 10
        return cell
    }
}
