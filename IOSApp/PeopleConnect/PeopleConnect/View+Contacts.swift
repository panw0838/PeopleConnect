//
//  ContactsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

let ContactNameFont = UIFont.systemFontOfSize(13)

let MoveMemberID:UInt64 = 1
let AddTagID    :UInt64 = 2
let DeleteTagID :UInt64 = 3
let RefreshID   :UInt64 = 4

let ContactNameHeight:CGFloat = 32

class ContactCell: UICollectionViewCell {
    var m_image  = UIImageView(frame: CGRectZero)
    var m_name   = UILabel(frame: CGRectZero)
    var m_id:UInt64 = 0
    var m_tag:Tag?
    var m_father:ContactsView?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        m_image.layer.cornerRadius = 10
        m_image.layer.masksToBounds = true
        m_name.font = ContactNameFont
        m_name.numberOfLines = 0
        m_name.lineBreakMode = .ByWordWrapping
        m_name.textAlignment = .Center
        addSubview(m_image)
        addSubview(m_name)
    }
    
    func reload(cID:UInt64, tag:Tag?) {
        m_id = cID
        m_tag = tag
        let width = self.frame.width
        m_image.frame = CGRectMake(0, 0, width, width)
        m_name.frame = CGRectMake(0, width, width, ContactNameHeight)
        switch m_id {
        case MoveMemberID:
            m_image.image = UIImage(named: "group_exchange")
            m_name.text   = "添加/移出组员"
            break
        case AddTagID:
            m_image.image = UIImage(named: "group_addtag")
            m_name.text   = "添加分组"
            break
        case DeleteTagID:
            m_image.image = UIImage(named: "group_deltag")
            m_name.text   = "删除分组"
            break
        case RefreshID:
            m_image.image = UIImage(named: "group_refresh")
            m_name.text   = ""
            break
        default:
            m_image.image = getPhoto(cID)
            m_name.text   = getName(cID)
            break
        }
    }
    
    func tagNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let tagName:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = tagName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }
    
    func tap() {
        switch m_id {
        case MoveMemberID:
            m_father?.performSegueWithIdentifier("ShowMoveMember", sender: m_tag)
            break
        case AddTagID:
            let alert = UIAlertController(title: "添加标签", message: "添加子标签到 "+m_tag!.m_tagName, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Default,
                handler: { action in
                    httpAddTag(self.m_tag!.m_tagID, name: (alert.textFields?.first?.text)!)})
            alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
                textField.placeholder = "标签名称"
                textField.addTarget(self, action: Selector("tagNameChanged:"), forControlEvents: .EditingChanged)
            }
            okAction.enabled = false
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.m_father?.presentViewController(alert, animated: true, completion: nil)
            break
        case DeleteTagID:
            let alert = UIAlertController(title: "删除标签", message: m_tag!.m_tagName, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Destructive,
                handler: { action in
                    httpRemTag(self.m_tag!)
            })
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.m_father?.presentViewController(alert, animated: true, completion: nil)
            break
        case RefreshID:
            if m_tag?.m_tagID == CellUsersTag {
                // todo
            }
            else if m_tag?.m_tagID == SuggestTag {
                httpGetSuggestContacts()
            }
            else if m_tag?.m_tagID == FaceToFaceTag {
                m_father?.startFaceToFace()
            }
            else if m_tag?.m_tagID == StrangerTag {
                m_father?.RefreshNearby()
            }
            break
        default:
            let contact = contactsData.m_contacts[m_id]
            if contact?.flag == 0 {
                ContactView.ContactID = m_id
                m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
            }
            else {
                let alert = UIAlertController(title: contact?.name, message: "", preferredStyle: .ActionSheet)
                let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                
                let msgAction = UIAlertAction(title: "发信息", style: .Default, handler: { action in
                    self.m_father?.m_convID = self.m_id
                    self.m_father?.performSegueWithIdentifier("StartConversation", sender: nil)
                })
                
                let callAction = UIAlertAction(title: "打电话", style: .Default, handler: { action in
                })
                
                let detailAction = UIAlertAction(title: "查看资料", style: .Default, handler: { action in
                    ContactView.ContactID = self.m_id
                    self.m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
                })
                
                alert.addAction(noAction)
                alert.addAction(msgAction)
                alert.addAction(callAction)
                alert.addAction(detailAction)
                
                self.m_father?.presentViewController(alert, animated: true, completion: nil)
            }
            break
        }
    }
}

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
        httpGetFaceUsers()
    }
    
    func startFaceToFace() {
        gLoadingView.setupCounting(10, delegate: self)
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
        
        if subTag.isSysTag() {
            subTag.m_numActions = (m_showEdits ? 2 : 0) // move add
        }
        else if subTag.isUserTag() {
             // move and delete
            subTag.m_numActions = (m_showEdits ? (1 + (subTag.canBeDelete() ? 1 : 0)) : 0)
        }
        else if subTag.isStrangerTag() {
            subTag.m_numActions = 1 // refresh
        }

        return subTag.m_numActions + subTag.m_members.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell
        let subTag  = contactsData.getSubTag(m_curTag, subIdx: indexPath.section)
        
        cell.m_father = self
        
        if indexPath.row < subTag.m_numActions {
            if subTag.isSysTag() {
                if indexPath.row == 0 {
                    cell.reload(MoveMemberID, tag: subTag)
                }
                else {
                    cell.reload(AddTagID, tag: subTag)
                }
            }
            else if subTag.isUserTag() {
                if indexPath.row == 0 {
                    cell.reload(MoveMemberID, tag: subTag)
                }
                else {
                    cell.reload(DeleteTagID, tag: subTag)
                }
            }
            else {
                cell.reload(RefreshID, tag: subTag)
            }
        }
        else {
            let contact = subTag.m_members[indexPath.row - subTag.m_numActions]
            cell.reload(contact, tag: subTag)
        }
        
        return cell
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
            width = (m_contacts.contentSize.width - 5*CGFloat(num)) / CGFloat(num)
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