//
//  View+Posts.swift
//  PeopleConnect
//
//  Created by apple on 18/12/30.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PostsView: PostsTable, UpdateLocationDelegate, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    func UpdateLocationSuccess() {
        httpSyncNearbyPost()
    }
    
    func UpdateLocationFail() {
    }
    
    @IBAction func switchPosts(sender: AnyObject) {
        let select = (sender as! UISegmentedControl).selectedSegmentIndex
        if select == 0 {
            setTable(m_posts, data: selfPosts, fullView: true)
        }
        else if select == 1 {
            setTable(m_posts, data: friendPosts, fullView: true)
        }
        else if select == 2 {
            setTable(m_posts, data: nearPosts, fullView: true)
            if userInfo.x == 0 && userInfo.y == 0 {
                userData.startLocate(self)
            }
        }
        m_posts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTable(m_posts, data: friendPosts, fullView: true)
        httpSyncPost()
        httpSyncContactPost(userInfo.userID)
    }
    /*
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let isSelf = m_data?.m_sorce == 0
        let post = m_data?.postAtIdx(indexPath.section)
        let comment = (isSelf ? post?.m_comments[indexPath.row-1] : post?.m_comments[indexPath.row])
        
        if comment!.from == userInfo.userID {
            let alert = UIAlertController(title: "删除评论", message: comment!.cmt, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Destructive,
                handler: { action in
                    httpDelComment(post!, cmt: comment!)
            })
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            let userName = contactsData.getContact((comment!.from))?.name
            let alert = UIAlertController(title: "回复 "+userName!, message: comment!.cmt, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Default,
                handler: { action in
                    let src = (self.m_data?.m_sorce != 0 ? (self.m_data?.m_sorce)! : comment!.src)
                    httpAddComment(post!, to: comment!.from, src: src, cmt: (alert.textFields?.first?.text)!)
                })
            alert.addTextFieldWithConfigurationHandler {
                (textField: UITextField!) -> Void in
                textField.placeholder = "最多输入50个字"
                textField.addTarget(self, action: Selector("commentChanged:"), forControlEvents: .EditingChanged)
                }
            okAction.enabled = false
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
*/
}

