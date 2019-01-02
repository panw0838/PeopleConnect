//
//  ContactsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class ContactCell: UICollectionViewCell {
    @IBOutlet weak var m_image: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    var m_contact:UInt64 = 0
}

class SubTagHeader: UICollectionReusableView {
    @IBOutlet weak var m_tagName: UILabel!
    @IBOutlet weak var m_delBtn: UIButton!
    @IBOutlet weak var m_editBtn: UIButton!
    @IBOutlet weak var m_refreshBtn: UIButton!
    var m_tag:Tag?
}

class ContactsView:
    UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    ContactDataDelegate,
    SearchContactCallback,
    UpdateLocationDelegate{
    
    @IBOutlet weak var m_tabsBar: UISegmentedControl!
    @IBOutlet weak var m_contacts: UICollectionView!
    @IBOutlet weak var m_createSubTag: UIBarButtonItem!
    
    var m_curTag: Int = 0
    var m_selectContact:UInt64 = 0
    
    @IBAction func ChangeTab(sender: AnyObject) {
        m_curTag = m_tabsBar.selectedSegmentIndex
        m_contacts.reloadData()
        m_createSubTag.enabled = (m_curTag < 4)
    }
    
    func ContactDataUpdate() {
        self.m_contacts.reloadData()
    }
    
    func SearchUpdateUI(uid:UInt64) {
        if uid == 0 {
            let error = UIAlertController(title: "查找失败", message: "", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
            error.addAction(okAction)
            presentViewController(error, animated: false, completion: nil)
        }
        else {
            ContactView.ContactID = uid
            performSegueWithIdentifier("ShowContact", sender: nil)
        }
    }

    func tagNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let tagName:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = tagName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }
    
    @IBAction func AddNewTag(sender: AnyObject) {
        let curTag = contactsData.m_tags[m_curTag]
        let alert = UIAlertController(title: "添加标签", message: "添加子标签到 "+curTag.m_tagName, preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                httpAddTag(curTag.m_tagID, name: (alert.textFields?.first?.text)!)})
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "标签名称"
            textField.addTarget(self, action: Selector("tagNameChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func DelSubTag(sender: AnyObject) {
        let header = sender.superview as! SubTagHeader
        let alert = UIAlertController(title: "删除标签", message: header.m_tagName.text, preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default,
            handler: { action in
                httpRemTag(header.m_tag!)
        })
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func UpdateLocationSuccess() {
        httpGetNearbyUsers()
    }
    
    func UpdateLocationFail() {
    }
    
    @IBAction func RefreshTag(sender: AnyObject) {
        let header = sender.superview as! SubTagHeader
        if header.m_tag!.m_tagID == 0xfe {
            httpGetPossibleContacts()
        }
        else if header.m_tag!.m_tagID == 0xff {
            userData.startLocate(self)
        }
    }
    
    @IBAction func SearchContact(sender: AnyObject) {
        let alert = UIAlertController(title: "搜索联系人", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let noAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: { action in
            httpSearchContact((alert.textFields?.first?.text)!)
        })
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "请输入手机号"
        }
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return contactsData.numSubTags(m_curTag)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let subTag = contactsData.getSubTag(m_curTag, subIdx: section)
        return subTag.m_members.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell
        let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        let contact = contactsData.m_contacts[subTag.m_members[indexPath.row]]
        cell.m_image.image = getPhoto(contact!.user)
        cell.m_image.layer.cornerRadius = 10
        cell.m_name.text = contact?.name
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader" {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagHeader", forIndexPath: indexPath) as! SubTagHeader
            let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        
            header.m_tagName.text = subTag.m_tagName
            header.m_editBtn.hidden = !subTag.canBeEdit()
            header.m_delBtn.hidden = !subTag.canBeDelete()
            header.m_refreshBtn.hidden = !subTag.isStrangerTag()
            header.m_tag = subTag
            return header
        }
        else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagFooter", forIndexPath: indexPath)
            return footer
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        let cID = subTag.m_members[indexPath.row]
        let name = contactsData.getContact(m_selectContact)?.name
        
        if subTag.isStrangerTag() {
            ContactView.ContactID = cID
            self.performSegueWithIdentifier("ShowContact", sender: nil)
        }
        else {
            let alert = UIAlertController(title: name, message: "", preferredStyle: .ActionSheet)
            let noAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
            
            let msgAction = UIAlertAction(title: "发信息", style: .Default, handler: { action in
                self.performSegueWithIdentifier("StartConversation", sender: nil)
            })
            
            let callAction = UIAlertAction(title: "打电话", style: .Default, handler: { action in
            })
            
            let detailAction = UIAlertAction(title: "查看资料", style: .Default, handler: { action in
                ContactView.ContactID = cID
                self.performSegueWithIdentifier("ShowContact", sender: nil)
            })
            
            alert.addAction(noAction)
            alert.addAction(msgAction)
            alert.addAction(callAction)
            alert.addAction(detailAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        m_curTag = item.tag
        m_contacts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contactsData.m_delegates.append(self)
        httpGetFriends()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowMoveMember" {
            let from = sender?.superview as! SubTagHeader
            let to = segue.destinationViewController as! MoveMemberView
            to.m_tag = from.m_tag
        }
        if segue.identifier == "StartConversation" {
            let to = segue.destinationViewController as! ConversationView
            to.m_conv = msgData.getConversation(self.m_selectContact)
        }
    }
}