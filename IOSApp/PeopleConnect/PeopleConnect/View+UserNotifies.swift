//
//  View+Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/12/28.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

class UNotifyCell:UITableViewCell {
    @IBOutlet weak var m_photo: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_message: UILabel!
    @IBOutlet weak var m_acceptBtn: UIButton!
    @IBOutlet weak var m_rejectBtn: UIButton!
    
    var m_uid:UInt64 = 0
    var m_father:UIViewController?
    
    func reload(uID:UInt64, msg:String, father:UIViewController) {
        m_uid = uID
        m_name.text = getName(uID)
        m_photo.image = getPhoto(uID)
        m_message.text = msg
        m_father = father
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("tapPhoto"))
        m_photo.addGestureRecognizer(tap)
        m_photo.userInteractionEnabled = true
        
        m_photo.layer.cornerRadius = 10
        m_photo.layer.masksToBounds = true
        m_acceptBtn.layer.cornerRadius = 10
        m_rejectBtn.layer.cornerRadius = 10
    }
    
    func tapPhoto() {
        ContactView.ContactID = m_uid
        m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
    }
    
    func showReqBtns(show:Bool) {
        m_acceptBtn.hidden = !show
        m_rejectBtn.hidden = !show
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

class UserNotifyView:UIViewController, ConvDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_table: UITableView!
    var m_conv:Conversation?
    
    func ConvUpdated() {
        m_table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_conv!.m_delegate = self
        self.title = m_conv?.m_name
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        m_conv!.m_delegate = nil
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_conv!.numMessages()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UNotifyCell") as! UNotifyCell
        let contact = m_conv!.getUserAt(indexPath.row)
        let message = m_conv!.getMessage(indexPath.row)
        cell.reload(contact, msg: message, father: self)

        if m_conv?.m_id == ConvType.ConvLikeUsr.rawValue {
            cell.showReqBtns(false)
        }
        else {
            cell.showReqBtns(true)
        }
        
        return cell
    }
}
