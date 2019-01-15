//
//  View+CreatePost.swift
//  PeopleConnect
//
//  Created by apple on 18/11/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class CreatePostView:
    UITableViewController,
    UITextFieldDelegate,
    UINavigationControllerDelegate,
    UpdateLocationDelegate {
    
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_strangerSee: UISwitch!
    @IBOutlet weak var m_createPostBtn: UIBarButtonItem!
    @IBOutlet weak var m_imgsPreview: ImgEditPreview!
    @IBOutlet weak var m_visibleTags: TagsView!
    @IBOutlet weak var m_visibleGroups: TagsView!
    
    func updateCreateBtn() {
        let writed = (m_imgsPreview.m_picks.count > 0 || m_desc.text?.characters.count > 0)
        let shared = (m_visibleTags.m_flag != 0 || m_strangerSee.on)
        m_createPostBtn.enabled = (writed && shared)
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
        let flag = m_visibleTags.m_flag
        let groups = Array<String>() // todo
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
        m_createPostBtn.enabled = false
        m_imgsPreview.m_controller = self
        m_visibleTags.m_controller = self
    }
    
    @IBAction func didEndTexting(sender: AnyObject) {
        m_desc.endEditing(true)
        updateCreateBtn()
    }
    
    let space:CGFloat = 8
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            let width = tableView.contentSize.width - space * 2
            return (width - PostPreViewGap*2) / 3 + space * 2
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            let width = tableView.contentSize.width - space * 2
            return contactsData.getTagsHeight(width) + space * 2
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if indexPath.section == 1 && indexPath.row == 0 {
            let width = tableView.contentSize.width - space * 2
            let height = (width - PostPreViewGap*2) / 3
            m_imgsPreview.frame = CGRectMake(space, space, width, height)
            m_imgsPreview.reloadEdit()
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            let width = tableView.contentSize.width - space * 2
            let height = contactsData.getTagsHeight(width)
            m_visibleTags.frame = CGRectMake(space, space, width, height)
            m_visibleTags.loadContactTags(width)
        }
        return cell
    }
}
