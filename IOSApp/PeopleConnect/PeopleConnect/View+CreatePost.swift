//
//  View+CreatePost.swift
//  PeopleConnect
//
//  Created by apple on 18/11/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class AttachmentCell:UICollectionViewCell {
    @IBOutlet weak var m_preview: UIImageView!
    
}

class TagCell:UITableViewCell {
    
}

class TagTable:UITableViewController {
    
    let undefine_section = 4
    var m_flag:UInt64 = 0
    var m_tags = Set<String>()
    
    @IBAction func tagSelected(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
        let dst = self.navigationController?.visibleViewController as! CreatePostView
        dst.m_flag = m_flag
        var visibleStr = ""
        for (i, tag) in m_tags.enumerate() {
            if i != 0 {
                visibleStr += ","
            }
            visibleStr += tag
        }
        dst.m_tags = visibleStr.isEmpty ? "没有好友可见" : visibleStr + "可见"
    }
    
    func getTagName(indexPath: NSIndexPath)->String {
        if indexPath.section == undefine_section {
            return "全部联系人"
        }
        else {
            let subTag = contactsData.getSubTag(indexPath.section, subIdx: indexPath.row)
            return subTag.m_tagName
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return contactsData.numMainTags() - 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsData.numSubTags(section)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TagSelectCell", forIndexPath: indexPath)
        cell.textLabel?.text = getTagName(indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let tag = contactsData.getSubTag(indexPath.section, subIdx: indexPath.row)
        m_flag &= (~tag.m_bit)
        m_tags.remove(getTagName(indexPath))
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tag = contactsData.getSubTag(indexPath.section, subIdx: indexPath.row)
        m_flag |= tag.m_bit
        m_tags.insert(getTagName(indexPath))
    }
}

class CreatePostView:UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var m_attachments: UICollectionView!
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_visibleTags: UILabel!
    var m_flag:UInt64 = 0
    var m_tags:String = "没有好友可见"
    
    @IBAction func CreatePost(sender: AnyObject) {
        let desc = m_desc.text
        let flag = UInt64(2)//UInt64(m_allowed.tag + 1)
        var datas = Array<NSData>()
        for image in m_atts {
            let data = UIImagePNGRepresentation(image)
            datas.append(data!)
        }
        httpSendPost(flag, desc: desc!, datas: datas)
    }
    
    var m_picker:UIImagePickerController = UIImagePickerController()
    var m_atts:Array<UIImage> = Array<UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_picker.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        m_visibleTags.text = m_tags
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        m_atts.append(image)
        m_attachments.reloadData()
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
        }
        else {
            cell.m_preview.image = UIImage(named: "plus")
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < m_atts.count {
            
        }
        else {
            m_picker.sourceType = .SavedPhotosAlbum
            self.presentViewController(m_picker, animated: true) {() -> Void in}
        }
    }

}
