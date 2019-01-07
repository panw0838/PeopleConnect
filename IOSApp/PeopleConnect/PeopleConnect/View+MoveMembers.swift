//
//  UpdateTagMemberView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/15.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class MembersHeader: UICollectionReusableView {
    @IBOutlet weak var m_name: UILabel!
    
}

class MoveMemberView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var m_title: UINavigationItem!
    @IBOutlet weak var m_table: UICollectionView!
    @IBOutlet weak var m_moveBtn: UIBarButtonItem!

    var m_tag:Tag?
    var m_inTagMembers:Array<ContactInfo> = Array<ContactInfo>()
    var m_outTagMembers:Array<ContactInfo> = Array<ContactInfo>()
    
    @IBAction func UpdateMembers(sender: AnyObject) {
        let bit = m_tag!.m_bit
        var addMembers:Array<UInt64> = Array<UInt64>()
        var remMembers:Array<UInt64> = Array<UInt64>()
        for member in m_inTagMembers {
            if (member.flag & bit) == 0 {
                addMembers.append(member.user)
            }
        }
        for member in m_outTagMembers {
            if (member.flag & bit) != 0 {
                remMembers.append(member.user)
            }
        }
        if addMembers.count != 0 || remMembers.count != 0 {
            httpMoveContacts(m_tag!, addMembers: addMembers, remMembers: remMembers)
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_table.registerClass(UserCell.classForCoder(), forCellWithReuseIdentifier: "UserCell")
        m_moveBtn.enabled = false
        reloadData()
    }
    
    func reloadData() {
        let bit = m_tag!.m_bit
        for contact in contactsData.m_contacts.values {
            if contact.isContact() {
                if contact.flag & bit == 0 {
                    m_outTagMembers.append(contact)
                }
                else {
                    m_inTagMembers.append(contact)
                }
            }
        }
        m_title.title = m_tag!.m_tagName
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? m_inTagMembers.count : m_outTagMembers.count
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == "UICollectionElementKindSectionHeader" {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "MembersHeader", forIndexPath: indexPath) as! MembersHeader
            header.m_name.text = indexPath.section == 0 ? "已包含成员" : "未包含成员"
            return header
        }
        else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "MembersFooter", forIndexPath: indexPath)
            return footer
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UserCell", forIndexPath: indexPath) as! UserCell
        let members = indexPath.section == 0 ? m_inTagMembers : m_outTagMembers
        cell.reload(members[indexPath.row].user)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        m_moveBtn.enabled = true
        if indexPath.section == 0 {
            let member = m_inTagMembers.removeAtIndex(indexPath.row)
            m_outTagMembers.append(member)
        }
        else {
            let member = m_outTagMembers.removeAtIndex(indexPath.row)
            m_inTagMembers.append(member)
        }
        m_table.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var width = m_table.contentSize.width
        for var num = 1; width > 65; num++ {
            width = m_table.contentSize.width / CGFloat(num)
        }
        return CGSizeMake(width, width+ContactNameHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
}
