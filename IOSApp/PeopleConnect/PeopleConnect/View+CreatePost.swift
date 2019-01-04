//
//  View+CreatePost.swift
//  PeopleConnect
//
//  Created by apple on 18/11/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

protocol RemoveAttDelegate {
    func removeAtt(idx:Int)
}

class AttachmentCell:UICollectionViewCell {

    @IBOutlet weak var m_preview: UIImageView!
    @IBOutlet weak var m_delete: UIButton!
    @IBOutlet weak var m_add: UIImageView!
    
    var m_idx = 0
    var m_delegate:RemoveAttDelegate?
    
    @IBAction func deleteAttachment(sender: AnyObject) {
        m_delegate?.removeAtt(m_idx)
    }
}

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
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    ImgPickerDelegate,
    UITextFieldDelegate,
    UINavigationControllerDelegate,
    RemoveAttDelegate,
    UpdateLocationDelegate {
    
    @IBOutlet weak var m_attachments: UICollectionView!
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_postTags: UICollectionView!
    @IBOutlet weak var m_postTagsCell: PostTags!
    @IBOutlet weak var m_postGroupsCell: PostGroups!
    @IBOutlet weak var m_postGroups: UICollectionView!
    @IBOutlet weak var m_strangerSee: UISwitch!
    @IBOutlet weak var m_createPostBtn: UIBarButtonItem!
    
    var m_picker = ImgPicker(maxCount: 9)
    var m_atts = Array<UIImage>()
    
    func updateCreateBtn() {
        m_createPostBtn.enabled = (m_atts.count > 0 || m_desc.text?.characters.count > 0)
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
        for image in m_atts {
            let data = compressImage(image)
            datas.append(data)
        }
        httpSendPost(flag, desc: desc, datas: datas, groups: groups, nearby: nearby)
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_picker.m_pickerDelegate = self
        m_postTags.allowsSelection = true
        m_postTags.allowsMultipleSelection = true
        m_postGroups.allowsSelection = true
        m_postGroups.allowsMultipleSelection = true
        m_createPostBtn.enabled = false
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
    
    func removeAtt(idx: Int) {
        m_atts.removeAtIndex(idx)
        m_attachments.reloadData()
    }
    
    func didFinishedPickImage(imgs: Array<PHAsset>) {
        let imgMgr = PHImageManager()
        let options = PHImageRequestOptions()
        
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = true
        options.resizeMode = .Exact
        options.synchronous = true
        
        m_atts.removeAll()
        
        for asset in imgs {
            let tarSize = CGSizeMake(1024*4, 1024*4)
            imgMgr.requestImageForAsset(asset, targetSize: tarSize, contentMode: .AspectFill, options: options, resultHandler: {(img:UIImage?, info:[NSObject:AnyObject]?)->Void in
                self.m_atts.append(img!)
                })
        }
        
        m_attachments.reloadData()
        updateCreateBtn()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_atts.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
        if indexPath.row < m_atts.count {
            cell.m_preview.image = m_atts[indexPath.row]
            cell.m_delete.hidden = false
            cell.m_add.hidden = true
        }
        else {
            cell.m_preview.image = nil
            cell.m_delete.hidden = true
            cell.m_add.hidden = false
        }
        cell.m_idx = indexPath.row
        cell.m_delegate = self
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < m_atts.count {
            
        }
        else {
            let navi = UINavigationController(rootViewController: m_picker)
            navi.delegate = self
            self.presentViewController(navi, animated: true, completion: nil)
        }
    }

}
