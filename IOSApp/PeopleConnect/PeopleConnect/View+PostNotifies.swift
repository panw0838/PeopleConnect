//
//  View+PostNotifies.swift
//  PeopleConnect
//
//  Created by apple on 19/1/1.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class PostNotifyCell:UITableViewCell {
    @IBOutlet weak var m_photo: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_notify: UILabel!
    @IBOutlet weak var m_post: UIImageView!
    
}


class PostNotifyView:UIViewController, MsgDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_table: UITableView!
    
    var m_data:Conversation?
    
    func MsgUpdated() {
        m_table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_data!.m_messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostNotifyCell") as! PostNotifyCell
        let notify = m_data?.m_messages[indexPath.row]
        cell.m_photo.image = getPhoto(notify!.from)
        cell.m_name.text = getName(notify!.from)
        cell.m_notify.text = notify?.getMessage()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let notify = m_data?.m_messages[indexPath.row]
        let post = getPost(notify!.src, pID: notify!.pID, oID: notify!.oID)
        if post != nil {
            SinglePostView.SinglePost    = post
            SinglePostView.SinglePostSrc = (notify!.oID == userInfo.userID ? UsrPosts : notify!.src)
            performSegueWithIdentifier("ShowPost", sender: nil)
        }
    }
}