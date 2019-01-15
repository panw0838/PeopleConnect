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
        nearPosts.Update()
    }
    
    func UpdateLocationFail() {
    }
    
    @IBAction func switchPosts(sender: AnyObject) {
        let select = (sender as! UISegmentedControl).selectedSegmentIndex
        if select == 0 {
            setTable(m_posts, data: selfPosts, showPhoto: false, showMsg: true)
            if selfPosts.m_needSync {
                selfPosts.Update()
            }
        }
        else if select == 1 {
            setTable(m_posts, data: friendPosts, showPhoto: true, showMsg: true)
            if friendPosts.m_needSync {
                friendPosts.Update()
            }
        }
        else if select == 2 {
            setTable(m_posts, data: nearPosts as PostData, showPhoto: true, showMsg: true)
            if userInfo.x == 0 && userInfo.y == 0 {
                userData.startLocate(self)
            }
        }
        else if select == 3 {
            if userInfo.groups.count == 0 {
                let alert = UIAlertController(title: "添加大学", message: "你尚未加入大学，点击确定搜索你的大学", preferredStyle: .Alert)
                let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                let okAction = UIAlertAction(title: "确定", style: .Default,
                    handler: { action in
                        self.performSegueWithIdentifier("ShowSearch", sender: nil)
                })
                alert.addAction(noAction)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else {
                let group = userInfo.groups[0]
                let postData = getGroupPost(group.name)
                setTable(m_posts, data: postData, showPhoto: true, showMsg: true)
            }
        }
        m_posts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userInfo.groups.count > 0 {
            let name = userInfo.groups[0].name
            m_tabs.setTitle(name, forSegmentAtIndex: 3)
        }
        
        setTable(m_posts, data: friendPosts, showPhoto: true, showMsg: true)
        friendPosts.Update()
        selfPosts.Update()
    }
}

