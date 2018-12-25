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

class PostsView: UIViewController, PostDataDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    @IBAction func switchPosts(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        //m_posts.registerNib(UINib(nibName: "PostHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_posts.registerClass(PostHeader.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_posts.registerClass(PostFooter.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostFooter")

        friendPosts.m_delegate = self
        
        httpSyncPost()
        m_posts.estimatedRowHeight = 16
        m_posts.rowHeight = UITableViewAutomaticDimension
    }
    
    func PostDataUpdated() {
        m_posts.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowContact" {
            let to = segue.destinationViewController as! ContactView
            to.m_contact = contactsData.m_contacts[ContactView.ContactID]!
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return friendPosts.numOfPosts()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendPosts.postAtIdx(section).m_comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        cell.m_comment.attributedText = comment.getAttrString()
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostHeader") as! PostHeader
        let post = friendPosts.postAtIdx(section)
        header.m_father = self
        header.reload(post, width:m_posts.contentSize.width, fullView: true)
        return header
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer =  tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostFooter") as! PostFooter
        footer.reload(m_posts.contentSize.width)
        return footer
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        return getTextHeight(comment.getString(), width: m_posts.contentSize.width, font: commentFont)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = friendPosts.postAtIdx(section)
        return post.getHeight(m_posts.contentSize.width, fullView: true)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        if comment.from == userInfo.userID {
            let alert = UIAlertController(title: "删除评论", message: comment.cmt, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Destructive,
                handler: { action in
                    httpDelComment(post, cmt: comment, pub: PubLvl_Friend)
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
                    httpAddComment(post, to: (comment.from), pub: PubLvl_Friend, cmt: (alert.textFields?.first?.text)!)
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
