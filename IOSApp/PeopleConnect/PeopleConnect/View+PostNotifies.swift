//
//  View+PostNotifies.swift
//  PeopleConnect
//
//  Created by apple on 19/1/1.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class PostNotifyCell:UITableViewCell {
    @IBOutlet weak var m_postImg: UIImageView!
    @IBOutlet weak var m_postText: UILabel!
    @IBOutlet var m_actors: [UIImageView]!
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
        return m_data!.m_posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostNotifyCell") as! PostNotifyCell
        let post = m_data?.m_posts[indexPath.row]
        
        if post?.numImages() > 0 {
            cell.m_postImg.hidden = false
            cell.m_postText.hidden = true
            cell.m_postImg.image = post?.getPreview(0)
        }
        else {
            cell.m_postImg.hidden = true
            cell.m_postText.hidden = false
            cell.m_postText.text = post?.m_info.content
        }
        
        for img in cell.m_actors {
            img.hidden = true
        }
        
        for (idx, actor) in post!.m_actors.enumerate() {
            cell.m_actors[idx].hidden = false
            cell.m_actors[idx].image = getPhoto(actor)
            if idx == cell.m_actors.count-1 {
                cell.m_actors[idx].image = UIImage(named: "more")
                break
            }
        }
        
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