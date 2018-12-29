//
//  PostsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var m_comment: UILabel!
}

class PostsTable: UIViewController, PostDataDelegate, UITableViewDataSource {
    
    var m_data: PostData? = nil
    var m_table: UITableView? = nil
    var m_fullView: Bool = true
    
    func setTable(table:UITableView, data:PostData, fullView: Bool) {
        m_data = data
        m_data?.m_delegate = self
        
        m_table = table
        m_table!.registerClass(PostHeader.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_table!.registerClass(PostFooter.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostFooter")
        m_table!.estimatedRowHeight = 16
        m_table!.rowHeight = UITableViewAutomaticDimension
        
        m_fullView = fullView
    }
    
    func PostDataUpdated() {
        m_table!.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return m_data!.numOfPosts()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_data!.postAtIdx(section).m_comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = m_data!.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        cell.m_comment.attributedText = comment.getAttrString()
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostHeader") as! PostHeader
        let post = m_data!.postAtIdx(section)
        header.m_father = self
        header.reload(post, width:m_table!.contentSize.width, fullView: m_fullView)
        return header
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer =  tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostFooter") as! PostFooter
        footer.reload(m_table!.contentSize.width)
        return footer
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = m_data!.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        return getTextHeight(comment.getString(), width: m_table!.contentSize.width, font: commentFont)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = m_data!.postAtIdx(section)
        return post.getHeight(m_table!.contentSize.width, fullView: m_fullView)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
}

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
            setTable(m_posts, data: friendPosts, fullView: true)
        }
        else if select == 1 {
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
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        if comment.from == userInfo.userID {
            let alert = UIAlertController(title: "删除评论", message: comment.cmt, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Destructive,
                handler: { action in
                    httpDelComment(post, cmt: comment)
            })
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            let userName = contactsData.getContact((comment.from))?.name
            let alert = UIAlertController(title: "回复 "+userName!, message: comment.cmt, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Default,
                handler: { action in
                    httpAddComment(post, to: (comment.from), cmt: (alert.textFields?.first?.text)!)
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
}
