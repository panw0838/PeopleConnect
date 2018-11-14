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
   
class ContactsView: UICollectionViewController {
    
    var m_index: Int = 0
    
    func setTabIndex(idx:Int) {
        m_index = idx
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return contactsData.numSubTags(m_index) + 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section == contactsData.numSubTags(m_index)) {
            return contactsData.membersOfMainTag(m_index).count
        }
        else {
            return contactsData.membersOfSubTag(m_index, subIdx: section-1).count
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell
        let members = (indexPath.section == contactsData.numSubTags(m_index)) ? contactsData.membersOfMainTag(m_index) : contactsData.membersOfSubTag(m_index, subIdx: indexPath.section)
        //cell.backgroundColor = UIColor.blueColor()
        cell.m_image.image = UIImage(named: "default_profile")
        cell.m_name.text = members[indexPath.row].name
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "SubTagHeader", forIndexPath: indexPath) as! SubTagHeader
        let tagName = indexPath.section == contactsData.numSubTags(m_index) ? "fff" : contactsData.nameOfSubTag(m_index, subIdx: indexPath.section)
        header.m_tagName.text = tagName
        return header
    }
}