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
    var m_tagID:UInt8 = 0
}

class ContactsView: UIViewController, UITabBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var m_tabsBar: UITabBar!
    @IBOutlet weak var m_contacts: UICollectionView!
    
    var m_curTag: Int = 0
    var m_selectContact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")

    func tagNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let tagName:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = tagName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }
    
    @IBAction func AddNewTag(sender: AnyObject) {
        let curTag = contactsData.getSubTag(m_curTag, subIdx: 0)
        let alert = UIAlertController(title: "添加标签", message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let subAction = UIAlertAction(title: "添加子标签到 "+curTag.m_tagName, style: .Default,
            handler: { action in
                self.httpAddTag(curTag.m_tagID, name: (alert.textFields?.first?.text)!)})
        let okAction = UIAlertAction(title: "添加新标签", style: .Default,
            handler: { action in
                self.httpAddTag(0, name: (alert.textFields?.first?.text)!)})
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
                textField.placeholder = "分组名"
                textField.addTarget(self, action: Selector("tagNameChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        if curTag.m_tagID != 2 {
            alert.addAction(subAction)
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func DelSubTag(sender: AnyObject) {
        let header = sender.superview as! SubTagHeader
        let alert = UIAlertController(title: "删除标签", message: header.m_tagName.text, preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default,
            handler: { action in
                self.httpRemTag(header.m_tagID)
        })
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func SearchContact(sender: AnyObject) {
        let alert = UIAlertController(title: "搜索联系人", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default,
            handler: {
                action in
                self.httpSearchContact((alert.textFields?.first?.text)!)
                //self.presentViewController(holding, animated: false, completion: nil)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "请输入手机号"
        }
        alert.addAction(cancelAction)
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
        //cell.backgroundColor = UIColor.blueColor()
        cell.m_image.image = UIImage(named: "default_profile")
        cell.m_name.text = subTag.m_members[indexPath.row].name
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagHeader", forIndexPath: indexPath) as! SubTagHeader
        let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        
        header.m_tagName.text = subTag.m_tagName
        header.m_editBtn.hidden = !subTag.canBeEdit()
        header.m_delBtn.hidden = !subTag.canBeDelete()
        header.m_tagID = subTag.m_tagID
        return header
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        m_selectContact = subTag.m_members[indexPath.row]
        self.performSegueWithIdentifier("ShowContact", sender: nil)
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        m_curTag = item.tag
        m_contacts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        httpGetContacts()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateTags() {
        m_tabsBar.items?.removeAll()
        var tagIdx = 0
        for tag in contactsData.m_tags {
            let newTab:UITabBarItem = UITabBarItem.init(title: tag.m_tagName, image: nil, tag: tagIdx)
            m_tabsBar.items?.append(newTab)
            tagIdx++
        }
        let newTab:UITabBarItem = UITabBarItem.init(title: "未分类", image: nil, tag: tagIdx)
        m_tabsBar.items?.append(newTab)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowMoveMember" {
            let from = sender?.superview as! SubTagHeader
            let to = segue.destinationViewController as! MoveMemberView
            to.m_tagID = from.m_tagID
        }
        if segue.identifier == "ShowContact" {
            let to = segue.destinationViewController as! ContactView
            to.m_contact = self.m_selectContact
        }
    }
}