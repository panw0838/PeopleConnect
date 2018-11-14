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
    
    var deltag:UInt8 = 0
    @IBAction func AddNewTag(sender: AnyObject) {
        //httpAddTag(0, name: "newtag")
        httpRemTag(deltag)
        deltag++
    }
    
    @IBAction func RemTag(sender: AnyObject) {
        httpRemTag(0)
    }
    
    @IBAction func AddContact(sender: AnyObject) {
        let editor = sender as! UITextField
        httpSearchContact(editor.text!)
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
        httpGetContacts()
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
}