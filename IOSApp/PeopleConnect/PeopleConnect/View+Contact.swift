//
//  ContactView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/17.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit


class ContactView: UIViewController, PostDataDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_background: UIImageView!
    @IBOutlet weak var m_posts: UITableView!
    
    static var ContactID:UInt64 = 0
    
    var m_contact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")
    var m_messege:String = ""
    var m_nameGood:Bool = false
    var m_messegeGood:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_posts.registerClass(PostHeader.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_posts.registerClass(PostFooter.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostFooter")
        contactPosts.m_delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        m_name.text = m_contact.name
        m_profile.image = UIImage(data: getContactPhoto(m_contact.user)!)
    }
    
    func PostDataUpdated() {
        m_posts.reloadData()
    }
    
    func requestNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        m_contact.name = (alert.textFields?.first?.text)!
        let nameSize = m_contact.name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
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
                httpRequestContact(self.m_contact.user, flag: 2, name: self.m_contact.name, messege: self.m_messege)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = self.m_contact.name
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return contactPosts.m_posts.count
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = contactPosts.m_posts[section]
        return post.getHeight(m_posts.contentSize.width, fullView: false)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = contactPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        return getTextHeight(comment.getString(), width: m_posts.contentSize.width, font: commentFont)
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostHeader") as! PostHeader
        let post = contactPosts.m_posts[section]
        header.m_father = self
        header.reload(post, width:m_posts.contentSize.width, fullView: false)
        return header
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer =  tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostFooter") as! PostFooter
        footer.reload(m_posts.contentSize.width)
        return footer
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactPosts.postAtIdx(section).m_comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = contactPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        cell.m_comment.attributedText = comment.getAttrString()
        return cell
    }
}

