//
//  UpdateTagMemberView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/15.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class MemberCell: UICollectionViewCell {
    @IBOutlet weak var m_image: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    
}

class MembersHeader: UICollectionReusableView {
    @IBOutlet weak var m_name: UILabel!
    
}

class MoveMemberView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var m_title: UINavigationItem!
    @IBOutlet weak var m_table: UICollectionView!

    var m_tagID:UInt8 = 0
    var m_inTagMembers:Array<ContactInfo> = Array<ContactInfo>()
    var m_outTagMembers:Array<ContactInfo> = Array<ContactInfo>()
    
    @IBAction func UpdateMembers(sender: AnyObject) {
        let bit:UInt64 = BitOne << UInt64(m_tagID)
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
            httpMoveContacts(m_tagID, addMembers: addMembers, remMembers: remMembers)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        let bit:UInt64 = BitOne << UInt64(m_tagID)
        for contact in contactsData.m_contacts.values {
            if contact.flag & bit == 0 {
                m_outTagMembers.append(contact)
            }
            else {
                m_inTagMembers.append(contact)
            }
        }
        m_title.title = contactsData.getTag(m_tagID)!.m_tagName
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? m_inTagMembers.count : m_outTagMembers.count
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "MembersHeader", forIndexPath: indexPath) as! MembersHeader
        header.m_name.text = indexPath.section == 0 ? "已包含成员" : "未包含成员"
        return header
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MemberCell", forIndexPath: indexPath) as! MemberCell
        let members = indexPath.section == 0 ? m_inTagMembers : m_outTagMembers
        //cell.backgroundColor = UIColor.blueColor()
        cell.m_image.image = UIImage(named: "default_profile")
        cell.m_name.text = members[indexPath.row].name
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
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
}
