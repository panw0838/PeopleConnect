//
//  View+CreatePost.swift
//  PeopleConnect
//
//  Created by apple on 18/11/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class PostTagCell:UICollectionViewCell {
    @IBOutlet weak var m_tagName: UILabel!
}

class PostTags:UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var m_tags:Array<Tag>?
    var m_flag:UInt64 = 0
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_tags!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PostTagCell", forIndexPath: indexPath) as! PostTagCell
        cell.m_tagName.text = m_tags![indexPath.row].m_tagName
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.lightGrayColor()
        m_flag &= ~(m_tags![indexPath.row].m_bit)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
       m_flag |= (m_tags![indexPath.row].m_bit)
        cell?.backgroundColor = UIColor(red: 0, green: 0.4, blue: 0.8, alpha: 1.0)
    }
}

class PostGroupCell:UICollectionViewCell {
    @IBOutlet weak var m_groupName: UILabel!
}

class PostGroups:UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var m_selectGroups = Set<UInt32>()
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userInfo.groups.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PostGroupCell", forIndexPath: indexPath) as! PostGroupCell
        cell.m_groupName.text = userInfo.groups[indexPath.row].name
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.lightGrayColor()
        m_selectGroups.remove(userInfo.groups[indexPath.row].id)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor(red: 0, green: 0.4, blue: 0.8, alpha: 1.0)
        m_selectGroups.insert(userInfo.groups[indexPath.row].id)
    }
}

class CreatePostView:
    UITableViewController,
    UITextFieldDelegate,
    UINavigationControllerDelegate,
    UpdateLocationDelegate {
    
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_postTags: UICollectionView!
    @IBOutlet weak var m_postTagsCell: PostTags!
    @IBOutlet weak var m_postGroupsCell: PostGroups!
    @IBOutlet weak var m_postGroups: UICollectionView!
    @IBOutlet weak var m_strangerSee: UISwitch!
    @IBOutlet weak var m_createPostBtn: UIBarButtonItem!
    @IBOutlet weak var m_imgsPreview: ImgPreview!
    
    func updateCreateBtn() {
        m_createPostBtn.enabled = (m_imgsPreview.m_picks.count > 0 || m_desc.text?.characters.count > 0)
    }
    
    func UpdateLocationSuccess() {
        updateCreateBtn()
    }
    
    func UpdateLocationFail() {
        m_strangerSee.setOn(false, animated: true)
        updateCreateBtn()
    }

    @IBAction func changeNearby(sender: AnyObject) {
        if m_strangerSee.on {
            userData.startLocate(self)
            m_createPostBtn.enabled = false
        }
    }
    
    @IBAction func CreatePost(sender: AnyObject) {
        let desc = m_desc.text!
        let flag = m_postTagsCell.m_flag
        let groups = Array(m_postGroupsCell.m_selectGroups)
        let nearby = m_strangerSee.on
        var datas = Array<NSData>()
        for image in m_imgsPreview.m_picks {
            let data = compressImage(image)
            datas.append(data)
        }
        httpSendPost(flag, desc: desc, datas: datas, groups: groups, nearby: nearby)
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_postTags.allowsSelection = true
        m_postTags.allowsMultipleSelection = true
        m_postGroups.allowsSelection = true
        m_postGroups.allowsMultipleSelection = true
        m_createPostBtn.enabled = false
        m_imgsPreview.m_controller = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        m_postTagsCell.m_tags = contactsData.getPostTags()
        m_postTagsCell.m_flag = 0
        m_postGroupsCell.m_selectGroups.removeAll()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        updateCreateBtn()
    }
    
    let pickerSpace:CGFloat = 8
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            let width = tableView.contentSize.width - pickerSpace * 2
            return (width - PostPreViewGap*2) / 3 + pickerSpace * 2
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if indexPath.section == 1 && indexPath.row == 0 {
            let width = tableView.contentSize.width - pickerSpace * 2
            m_imgsPreview.frame = CGRectMake(pickerSpace, pickerSpace, width, (width - PostPreViewGap*2) / 3)
            m_imgsPreview.reloadEdit()
            print(m_imgsPreview.frame)
            print(tableView.contentSize)
        }
        return cell
    }
}
