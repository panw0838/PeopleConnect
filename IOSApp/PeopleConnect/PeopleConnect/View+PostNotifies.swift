//
//  View+PostNotifies.swift
//  PeopleConnect
//
//  Created by apple on 19/1/1.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class PostNotifyCell:UITableViewCell {
    @IBOutlet weak var m_postPreview: ImgPreview!
    @IBOutlet weak var m_postText: UILabel!
    @IBOutlet var m_actorPhotos: [UIImageView]!
    @IBOutlet weak var m_message: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func reload(post:Post, msg:String) {
        m_message.text = msg
        m_postPreview.userInteractionEnabled = false
        if post.numImages() > 0 {
            m_postText.hidden = true
            m_postPreview.hidden = false
            m_postPreview.reload(post)
        }
        else {
            m_postPreview.hidden = true
            m_postText.hidden = false
            m_postText.text = post.m_info.content
        }
        
        for img in m_actorPhotos {
            img.hidden = true
        }
        
        for (idx, actor) in post.m_actors.enumerate() {
            m_actorPhotos[idx].hidden = false
            m_actorPhotos[idx].image = getPhoto(actor)
            m_actorPhotos[idx].layer.cornerRadius = 20
            m_actorPhotos[idx].layer.masksToBounds = true
            m_actorPhotos[idx].layer.borderWidth = 2
            m_actorPhotos[idx].layer.borderColor = UIColor.whiteColor().CGColor
            if idx == m_actorPhotos.count-1 {
                break
            }
        }
        
    }
}


class PostNotifyView:UIViewController, MsgDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_table: UITableView!
    
    var m_data:PostNotifies?
    
    func MsgUpdated() {
        m_table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var cIDs = Array<UInt64>()
        for message in m_data!.m_messages {
            if getContactPhoto(message.from) == nil {
                cIDs.append(message.from)
            }
        }
        // sync photos
        if cIDs.count > 0 {
            httpGetPhotos(cIDs,
                passed: {()->Void in
                    self.m_table.reloadData()
                },
                failed: nil)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_data!.numMessages()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostNotifyCell") as! PostNotifyCell
        let post = m_data?.m_posts[indexPath.row]
        let msg = m_data?.getMessage(indexPath.row)
        cell.reload(post!, msg: msg!)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = m_data?.m_posts[indexPath.row]
        let postData = post?.m_father
        
        if postData != nil && postData!.lockPost(post!.m_info.id, oID: post!.m_info.user) {
            SinglePostView.postData = postData
            performSegueWithIdentifier("ShowPost", sender: nil)
        }
    }
}