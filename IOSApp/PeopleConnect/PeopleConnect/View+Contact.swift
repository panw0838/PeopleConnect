//
//  ContactView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/17.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit


class ContactView: PostsTable, UITableViewDelegate {
    
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_background: UIImageView!
    @IBOutlet weak var m_posts: UITableView!
    @IBOutlet weak var m_reqBtn: UIButton!
    
    static var ContactID:UInt64 = 0
    
    var m_noteName:String = ""
    var m_messege:String = ""
    var m_nameGood:Bool = false
    var m_messegeGood:Bool = false
    var m_preDelegate:PostDataDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_profile.layer.cornerRadius = 10
        m_reqBtn.layer.cornerRadius = 10
        m_reqBtn.hidden = true
        
        m_name.text = getName(ContactView.ContactID)
        m_profile.image = getPhoto(ContactView.ContactID)

        if getContactPhoto(ContactView.ContactID) == nil {
            let cIDs:Array<UInt64> = [ContactView.ContactID]
            httpGetPhotos(cIDs,
                passed: {()->Void in
                    self.m_profile.image = getPhoto(ContactView.ContactID)
                },
                failed: nil)
        }

        var postData:PostData?
        
        if ContactView.ContactID == userInfo.userID {
            postData = selfPosts
        }
        else {
            if contactsPosts[ContactView.ContactID] == nil {
                postData = PostData(cid: ContactView.ContactID)
                contactsPosts[ContactView.ContactID] = postData
            }
            else {
                postData = contactsPosts[ContactView.ContactID]
            }
        }
            
        m_preDelegate = postData?.m_delegate
        setTable(m_posts, data: postData!, showPhoto: false, showMsg: false)
        postData?.Update()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        m_data?.setDelegate(m_preDelegate)
        ContactView.ContactID = 0
    }
    
    func requestNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        self.m_name.text = (alert.textFields?.first?.text)!
        let nameSize = self.m_name.text!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        m_nameGood = (nameSize > 0 && nameSize < 18)
        okAction.enabled = (m_nameGood && m_messegeGood)
    }
    
    func requestMessegeChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        m_messege = (alert.textFields?.last?.text)!
        let nameSize = m_messege.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        m_messegeGood = (nameSize > 0 && nameSize < 18)
        okAction.enabled = (m_nameGood && m_messegeGood)
    }
    
    @IBAction func RequestContact() {
        let alert = UIAlertController(title: "添加联系人", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default,
            handler: { action in
                httpRequestContact(ContactView.ContactID, name: self.m_name.text!, messege: self.m_messege)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = self.m_name.text
            textField.addTarget(self, action: Selector("requestNameChanged:"), forControlEvents: .EditingChanged)
        }
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "好友请求信息"
            textField.addTarget(self, action: Selector("requestMessegeChanged:"), forControlEvents: .EditingChanged)
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func RemContact(sender: AnyObject) {
    }
}

