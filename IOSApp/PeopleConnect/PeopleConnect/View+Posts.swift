//
//  PostsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PreviewCell: UICollectionViewCell {
    @IBOutlet weak var m_preview: UIImageView!
}

class CommentCell: UITableViewCell {
    @IBOutlet weak var m_comment: UILabel!
}

class PostCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_article: UILabel!
    @IBOutlet weak var m_previews: UICollectionView!
    @IBOutlet weak var m_comments: UITableView!
    @IBOutlet weak var m_stack: UIStackView!
    @IBOutlet weak var m_liktBtn: UIButton!
    
    @IBOutlet weak var m_commentConstrain: NSLayoutConstraint!
    
    var m_father:PostsView? = nil
    
    func commentChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }

    @IBAction func actComment(sender: AnyObject) {
        let alert = UIAlertController(title: "添加评论", message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                httpCommentPost(self.m_post!, to:self.m_post!.m_info.user, pub: PubLvl_Friend, re: 0, cmt: (alert.textFields?.first?.text)!)
            })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "最多输入18个字"
            textField.addTarget(self, action: Selector("commentChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.m_father!.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func actLike(sender: AnyObject) {
    }
    
    var m_idx:Int = 0
    var m_post:Post? = nil
    var m_cellSize:CGFloat = 0.0
    let preGap:CGFloat = 5.0

    func reload() {
        m_post = postData.postAtIdx(m_idx)

        let contact = contactsData.getContact((m_post?.m_info.user)!)
        m_name.text = contact?.name
        m_article.text = m_post?.m_info.content
        
        // sub view rects
        m_stack.frame.size = CGSizeMake(m_stack.frame.width, ((m_post?.m_stackHeight)!))
        
        m_article.backgroundColor = UIColor.yellowColor()
        
        let text:NSString = m_article.text!
        if text.length > 0 {
            m_article.hidden = false
            m_article.frame.size = CGSizeMake(m_article.frame.width, (m_post?.m_contentHeight)!)
        }
        else {
            m_article.hidden = true
        }
        
        if m_post?.m_imgUrls.count > 0 {
            m_previews.hidden = false
            m_previews.dataSource = self
            m_previews.delegate = self
            m_previews.frame.size = CGSizeMake(m_previews.frame.width, (m_post?.m_previewHeight)!)
            m_previews.reloadData()
        }
        else {
            m_previews.hidden = true
        }
        
        if m_post?.m_comments.count > 0 {
            m_comments.hidden = false
            m_comments.dataSource = self
            m_comments.delegate = self
            m_comments.frame.size = CGSizeMake(m_comments.frame.width, (m_post?.m_commentHeight)!)
            m_commentConstrain.constant = (m_post?.m_commentHeight)!
            m_comments.reloadData()
        }
        else {
            m_comments.hidden = true
        }
    }
        
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_post?.m_info.files.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PreviewCell", forIndexPath: indexPath) as! PreviewCell
        let imgKey = m_post?.m_imgKeys[indexPath.row]
        if postData.m_snaps[imgKey!] == nil {
            cell.m_preview.image = UIImage(named: "loading")
        }
        else {
            cell.m_preview.image = postData.m_snaps[imgKey!]
        }
        
        let frame = m_previews.frame
        if indexPath.row < 9 {
            let geo = m_post!.m_previewLayout[indexPath.row]
            let width  = (frame.width  - preGap * (geo.width-1)) / geo.width
            let height = (frame.height - preGap * (geo.height-1)) / geo.height
            let x = (width  + preGap) * geo.origin.x
            let y = (height + preGap) * geo.origin.y
            cell.frame = CGRectMake(x, y, width, height)
        }
        else {
            cell.frame = frame
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        /*
        http.getFile((m_post?.m_imgUrls[indexPath.row])!,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
        let data = response as! NSData
        cell.m_preview.image = UIImage(data: data)
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        print("请求失败")
        }
        )
        */
        return
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (m_post?.m_comments.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let comment = m_post?.m_comments[indexPath.row]
        let userName = contactsData.getContact(comment!.from)?.name
        let commentStr = userName! + ":" + comment!.cmt
        cell.m_comment.text = commentStr
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return (m_post?.m_commentLayout[indexPath.row])!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //todo comment
    }
}

class PostsView: UIViewController, PostRequestCallback, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    @IBAction func switchPosts(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        httpSyncPost()
        postCallbacks.append(self)
        m_posts.estimatedRowHeight = 80
        m_posts.rowHeight = UITableViewAutomaticDimension
    }
    
    func PostUpdateUI() {
        m_posts.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postData.numOfPosts()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostCell
        let post = postData.postAtIdx(indexPath.row)
        let contentWidth = m_posts.contentSize.width - PostItemGapF * 2
        cell.m_idx = indexPath.row
        cell.m_father = self
        post.setupGeometry(contentWidth)
        cell.reload()
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = postData.postAtIdx(indexPath.row)
        let contentWidth = m_posts.contentSize.width - PostItemGapF * 2
        post.setupGeometry(contentWidth)
        return post.m_height
    }
}
