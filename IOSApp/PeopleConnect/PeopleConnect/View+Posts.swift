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
}

