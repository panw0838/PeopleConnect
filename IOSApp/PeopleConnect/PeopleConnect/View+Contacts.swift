//
//  ContactsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

let ContactNameFont = UIFont.systemFontOfSize(11)

let MoveMemberID:UInt64 = 1
let AddTagID    :UInt64 = 2
let DeleteTagID :UInt64 = 3

let CellBookID  :UInt64 = 4
let RecommentID :UInt64 = 5
let FaceToFaceID:UInt64 = 6
let NearbyID    :UInt64 = 7

let MaxActionID :UInt64 = 8

let ContactNameHeight:CGFloat = 28

let TagActionsImgs:Dictionary<TagAction, String> = [
    .MoveMember:    "group_exchange",
    .AddTag:        "group_addtag",
    .DelTag:        "group_deltag",

    .SearchCell:    "group_cell",
    .SearchConn:    "group_recoment",
    .SearchFace:    "group_facetoface",
    .SearchNear:    "group_near"]

let TagActionsNames:Dictionary<TagAction, String> = [
    .MoveMember:    "添加/移出组员",
    .AddTag:        "添加分组",
    .DelTag:        "删除分组",

    .SearchCell:    "搜索手机联系人",
    .SearchConn:    "搜索共同认识的人",
    .SearchFace:    "同时按面对面加好友",
    .SearchNear:    "点击搜索附近的人"]

class SubTagHeader: UICollectionReusableView {
    @IBOutlet weak var m_tagName: UILabel!
}

class ContactsView:
    UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    ContactDataDelegate,
    CounterDelegate,
    SearchContactCallback,
    UpdateLocationDelegate{
    
    @IBOutlet weak var m_tabsBar: UISegmentedControl!
    @IBOutlet weak var m_contacts: UICollectionView!
    
    var m_curTag: Int = 0
    var m_convID:UInt64 = 0
    var m_showEdits = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_contacts.registerClass(ContactCell.classForCoder(), forCellWithReuseIdentifier: "ContactCell")
        m_contacts.registerClass(ActionCell.classForCoder(), forCellWithReuseIdentifier: "ActionCell")
        contactsData.setDelegate(self)
        httpGetFriends()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: Selector("EditContactsTable:"))
    }
    
    @IBAction func ChangeTab(sender: AnyObject) {
        m_curTag = m_tabsBar.selectedSegmentIndex
        m_contacts.reloadData()
    }
    
    func ContactDataUpdate() {
        self.m_contacts.reloadData()
    }
    
    func counterFinished() {
        httpDidFaceUsers()
    }
    
    func counterInvoke() {
        httpGetFaceUsers()
    }
    
    func startFaceToFace() {
        gLoadingView.setupCounting(11, invokeSeconds: 4, delegate: self)
        userData.startLocate(self)
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

    var m_searchNear = false

    func UpdateLocationSuccess() {
        if m_searchNear {
            httpGetNearbyUsers()
            m_searchNear = false
        }
        else {
            httpRegFaceUsers(
                {()->Void in
                    gLoadingView.startCounting()
                },
                failed: {(err:String?)->Void in
                    gLoadingView.stopCounting()
                })
        }
    }
    
    func UpdateLocationFail() {
        m_searchNear = false
    }
    
    func RefreshNearby() {
        userData.startLocate(self)
        m_searchNear = true
    }
    
    @IBAction func DoneContactsTable(sender: AnyObject) {
        m_showEdits = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: Selector("EditContactsTable:"))
        m_contacts.reloadData()
    }
    
    @IBAction func EditContactsTable(sender: AnyObject) {
        m_showEdits = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("DoneContactsTable:"))
        m_contacts.reloadData()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return contactsData.numSubTags(m_curTag)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let subTag = contactsData.getSubTag(m_curTag, subIdx: section)
        subTag.reloadActions(m_showEdits)
        return subTag.m_actions.count + subTag.m_members.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let subTag  = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        
        if indexPath.row < subTag.m_actions.count {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ActionCell", forIndexPath: indexPath) as! ActionCell
            cell.reloadAction(subTag.m_actions[indexPath.row], tag: subTag)
            cell.m_father = self
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell
            let contact = subTag.m_members[indexPath.row - subTag.m_actions.count]
            cell.reload(contact)
            cell.m_father = self
            return cell
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader" {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagHeader", forIndexPath: indexPath) as! SubTagHeader
            let subTag = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        
            header.m_tagName.text = subTag.m_tagName
            return header
        }
        else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagFooter", forIndexPath: indexPath)
            return footer
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = m_contacts.cellForItemAtIndexPath(indexPath) as! ContactCell
        cell.tap()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var width = m_contacts.contentSize.width
        for var num = 1; width > 65; num++ {
            width = m_contacts.contentSize.width / CGFloat(num)
        }
        return CGSizeMake(width, width+ContactNameHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        m_curTag = item.tag
        m_contacts.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowMoveMember" {
            let to = segue.destinationViewController as! MoveMemberView
            to.m_tag = sender as? Tag
        }
        if segue.identifier == "StartConversation" {
            let to = segue.destinationViewController as! ConversationView
            to.m_conv = msgData.popConversation(self.m_convID)
        }
    }
}