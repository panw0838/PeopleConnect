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

class PostHeader: UITableViewHeaderFooterView {
    
    //@IBOutlet weak var m_profile: UIImageView!
    //@IBOutlet weak var m_name: UILabel!
    //@IBOutlet weak var m_article: UILabel!
    //@IBOutlet weak var m_previews: ImgPreview!
    //@IBOutlet weak var m_liktBtn: UIButton!

    var m_profile    = UIImageView(frame: CGRectZero)
    var m_name       = UILabel(frame: CGRectZero)
    var m_article    = UILabel(frame: CGRectZero)
    var m_previews   = ImgPreview(frame: CGRectZero)
    var m_liktBtn    = UIButton(frame: CGRectZero)
    var m_commentBtn = UIButton(frame: CGRectZero)
    
    var m_post:Post? = nil
    var m_father:PostsView? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    func initSubviews() {
        self.addSubview(m_profile)
        m_name.textColor = UIColor.blueColor()
        m_name.font = nameFont
        self.addSubview(m_name)
        self.addSubview(m_article)
        self.addSubview(m_previews)
        self.addSubview(m_liktBtn)
        m_commentBtn.addTarget(self, action: "actComment", forControlEvents: .TouchDown)
        self.addSubview(m_commentBtn)
    }
    
    func commentChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 50)
    }

    @IBAction func actComment(sender: AnyObject) {
        let alert = UIAlertController(title: "添加评论", message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                httpAddComment(self.m_post!, to:0, pub: PubLvl_Friend, cmt: (alert.textFields?.first?.text)!)
            })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "最多输入50个字"
            textField.addTarget(self, action: Selector("commentChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.m_father!.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func actLike(sender: AnyObject) {
    }
    

    func reload(post:Post) {
        m_post = post
        
        let contact = contactsData.getContact((m_post?.m_info.user)!)
        
        m_profile.image = UIImage(named: "default_profile")
        m_profile.frame = CGRectMake(0, 0, 40, 40)
        
        m_name.text = contact?.name
        m_name.frame = CGRectMake(45, 0, 100, 20)
        
        m_commentBtn.imageView?.image = UIImage(named: "comment_cmt")
        m_commentBtn.frame = CGRectMake(200, 20, 25, 25)

        m_liktBtn.imageView?.image = UIImage(named: "comment_like")
        m_liktBtn.frame = CGRectMake(250, 20, 25, 25)

        m_article.text = m_post?.m_info.content
        
        // sub view rects
        m_article.backgroundColor = UIColor.yellowColor()
        
        if m_post?.m_info.content.characters.count > 0 {
            m_article.hidden = false
            m_article.frame = CGRectMake(0, (m_post?.m_contentY)!, self.frame.width, (m_post?.m_contentHeight)!)
        }
        else {
            m_article.hidden = true
        }
        
        if m_post?.m_imgUrls.count > 0 {
            m_previews.hidden = false
            m_previews.frame = CGRectMake(0, (m_post?.m_previewY)!, self.frame.width, (m_post?.m_previewHeight)!)
            m_previews.reload(m_post!)
        }
        else {
            m_previews.hidden = true
        }
    }
}

class PostsView: UIViewController, PostRequestCallback, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    @IBAction func switchPosts(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        //m_posts.registerNib(UINib(nibName: "PostHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_posts.registerClass(PostHeader.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostHeader")
        
        httpSyncPost()
        postCallbacks.append(self)
        m_posts.estimatedRowHeight = 80
        m_posts.rowHeight = UITableViewAutomaticDimension
    }
    
    func PostUpdateUI() {
        m_posts.reloadData()
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

        let fromName = contactsData.getContact(comment.from)?.name
        var toName = ""
        var cmtStr = ""
        var toStart = 0
        var toLength = 0

        post.setupGeometry(m_posts.contentSize.width)
        
        if comment.to != 0 {
            toName = (contactsData.getContact(comment.to)?.name)!
            cmtStr = fromName! + "回" + toName + ":" + comment.cmt
            toStart = (fromName?.characters.count)! + 1
            toLength = toName.characters.count
        }
        else {
            cmtStr = fromName! + ":" + comment.cmt
        }
        
        let attStr = NSMutableAttributedString(string: cmtStr)
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        
        attStr.setAttributes(attDic, range: NSMakeRange(0, cmtStr.characters.count))
        attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: NSMakeRange(0, (fromName?.characters.count)!))
        
        if comment.to != 0 {
            attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: NSMakeRange(toStart, toLength))
        }
        
        cell.m_comment.attributedText = attStr
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostHeader") as! PostHeader
        let post = friendPosts.postAtIdx(section)
        header.m_father = self
        header.reload(post)
        return header
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        let height = getTextHeight(comment.getString(), width: m_posts.contentSize.width, font: commentFont)
        return height
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = friendPosts.postAtIdx(section)
        let contentWidth = m_posts.contentSize.width
        post.setupGeometry(contentWidth)
        return post.m_height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let post = friendPosts.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        if comment.from == userInfo.userID {
            let alert = UIAlertController(title: "删除评论", message: "", preferredStyle: .Alert)
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
