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
    
}

class SubTagHeader: UICollectionReusableView {
    @IBOutlet weak var m_tagName: UILabel!
    
}

class ContactsView: UIViewController, UITabBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var m_tabsBar: UITabBar!
    @IBOutlet weak var m_contacts: UICollectionView!
    
    var m_curTag: Int = 0
    
    @IBAction func AddNewTag(sender: AnyObject) {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "father":NSNumber(int: 0), "name":"newtag"]
        http.postRequest("addtag", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                    if (jsonObj != nil) {
                        let dict: NSDictionary = jsonObj as! NSDictionary
                        let tagID: UInt8 = (UInt8)((dict["tag"]?.integerValue)!)
                        let newTag: TagInfo = TagInfo(id: tagID, father: 0, name: "newTag")
                        let newTab: UITabBarItem = UITabBarItem.init(title: "newtag", image: nil, tag: userTags.count)
                        userTags.append(newTag)
                        contactsData.addTag(Tag(id: tagID, father: 0, name: "newtag"))
                        self.m_tabsBar.items?.append(newTab)
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            })
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return contactsData.numSubTags(m_curTag) + 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section == contactsData.numSubTags(m_curTag)) {
            return contactsData.membersOfMainTag(m_curTag).count
        }
        else {
            return contactsData.membersOfSubTag(m_curTag, subIdx: section-1).count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell
        let members = (indexPath.section == contactsData.numSubTags(m_curTag)) ? contactsData.membersOfMainTag(m_curTag) : contactsData.membersOfSubTag(m_curTag, subIdx: indexPath.section)
        //cell.backgroundColor = UIColor.blueColor()
        cell.m_image.image = UIImage(named: "default_profile")
        cell.m_name.text = members[indexPath.row].name
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagHeader", forIndexPath: indexPath) as! SubTagHeader
        var tagName = ""
        if indexPath.section == contactsData.numSubTags(m_curTag) {
            tagName = indexPath.section == 0 ? "全部" : "其他"
            tagName += contactsData.nameOfMainTag(m_curTag)
        }
        else {
            tagName = contactsData.nameOfSubTag(m_curTag, subIdx: indexPath.section)
        }
        header.m_tagName.text = tagName
        return header
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        m_curTag = item.tag
        m_contacts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContacts()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateTags() {
        m_tabsBar.items?.removeAll()
        var tagIdx = 0
        for tag in contactsData.m_tags {
            let newTab:UITabBarItem = UITabBarItem.init(title: tag.tagName, image: nil, tag: tagIdx)
            m_tabsBar.items?.append(newTab)
            tagIdx++
        }
    }
    
    func requestContacts() {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
        http.postRequest("contacts", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                        contacts.removeAll()
                        userTags.removeAll()
                        
                        if let tagObjs = json["tags"] as? [AnyObject] {
                            for case let tagObj in (tagObjs as? [[String:AnyObject]])! {
                                if let tag = TagInfo(json: tagObj) {
                                    userTags.append(tag)
                                }
                            }
                        }
                        
                        if let contactObjs = json["contacts"] as? [AnyObject] {
                            for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                                if let contact = ContactInfo(json: contactObj) {
                                    contacts.append(contact)
                                }
                            }
                        }
                        contactsData.loadContacts()
                        self.updateTags()
                        self.m_contacts.reloadData()
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
}