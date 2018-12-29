//
//  View+PostHeader.swift
//  PeopleConnect
//
//  Created by apple on 18/12/12.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PostFooter: UITableViewHeaderFooterView {
    static let Height:CGFloat = 21.0
    
    var m_view:UIView = UIView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        m_view.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(m_view)
    }
    
    func reload(width:CGFloat) {
        m_view.frame = CGRectMake(0, 10, width, 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PostHeader: UITableViewHeaderFooterView {

    var m_photo      = UIImageView(frame: CGRectZero)
    var m_name       = UILabel(frame: CGRectZero)
    
    var m_showAllBtn = UIButton(frame: CGRectZero)
    var m_article    = UILabel(frame: CGRectZero)
    
    var m_previews   = ImgPreview(frame: CGRectZero)
    
    var m_liktBtn    = UIButton(frame: CGRectZero)
    var m_commentBtn = UIButton(frame: CGRectZero)
    var m_deleteBtn  = UIButton(frame: CGRectZero)
    
    var m_post:Post? = nil
    var m_father:UIViewController? = nil
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    func clickContact() {
        ContactView.ContactID = (m_post?.m_info.user)!
        m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
    }
    
    func initSubviews() {
        let tapPhoto = UITapGestureRecognizer(target: self, action: Selector("clickContact"))

        m_photo.contentMode = .ScaleAspectFill;
        m_photo.userInteractionEnabled = true;
        m_photo.layer.masksToBounds = true;
        m_photo.layer.cornerRadius = 10
        m_photo.addGestureRecognizer(tapPhoto)
        self.addSubview(m_photo)
        
        m_name.textColor = linkTextColor
        m_name.font = nameFont
        self.addSubview(m_name)
        
        m_showAllBtn.titleLabel?.font = articleFont
        m_showAllBtn.contentHorizontalAlignment = .Left
        m_showAllBtn.backgroundColor = UIColor.clearColor()
        m_showAllBtn.setTitle("全文", forState: .Normal)
        m_showAllBtn.setTitleColor(hlTextColor, forState: .Normal)
        //m_showAllBtn.addTarget(self, action: "showAllArticle", forControlEvents: .TouchUpInside)
        self.addSubview(m_showAllBtn)
        
        m_article.lineBreakMode = .ByWordWrapping
        m_article.numberOfLines = 0
        m_article.font = articleFont
        self.addSubview(m_article)
        
        self.addSubview(m_previews)
        
        m_liktBtn.setImage(UIImage(named: "post_like"), forState: .Normal)
        self.addSubview(m_liktBtn)
        
        m_commentBtn.setImage(UIImage(named: "post_cmt"), forState: .Normal)
        m_commentBtn.addTarget(self, action: Selector("actComment:"), forControlEvents: .TouchDown)
        self.addSubview(m_commentBtn)
        
        m_deleteBtn.setImage(UIImage(named: "post_delete"), forState: .Normal)
        m_deleteBtn.addTarget(self, action: Selector("deletePost:"), forControlEvents: .TouchDown)
        self.addSubview(m_deleteBtn)
    }
    
    func commentChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let len = input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (len > 0 && len < 50)
    }
    
    @IBAction func actComment(sender: AnyObject) {
        let alert = UIAlertController(title: "添加评论", message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                httpAddComment(self.m_post!, to:0, src: (self.m_post!.m_father?.m_sorce)!, cmt: (alert.textFields?.first?.text)!)
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
    
    @IBAction func deletePost(sender: AnyObject) {
        let alert = UIAlertController(title: "删除动态", message: self.m_post?.m_info.content, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Destructive,
            handler: { action in
                httpDeletePost(self.m_post!)
        })
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.m_father!.presentViewController(alert, animated: true, completion: nil)
    }

    func reload(post:Post, width:CGFloat, fullView:Bool) {
        m_post = post
        let selfPost = (m_post?.m_father?.m_sorce == 0)
        var buttom:CGFloat = 0.0
        
        if fullView {
            let contact = contactsData.getContact((m_post?.m_info.user)!)
            
            m_photo.image = getPhoto((m_post?.m_info.user)!)
            m_photo.frame = CGRectMake(0, 0, PostPhotoSize, PostPhotoSize)
            buttom = PostPhotoSize + PostItemGapF
            
            m_name.text = contact?.name
            m_name.frame = CGRectMake(PostPhotoSize + PostItemGapF, 0, width, 20)
        }
        else {
            m_photo.hidden = true
            m_name.hidden = true
        }
        
        if m_post?.m_info.content.characters.count > 0 {
            let height = getTextHeight(post.m_info.content, width: width, font: articleFont)
            m_article.text = m_post?.m_info.content
            m_article.hidden = false
            m_article.sizeToFit()
            m_article.frame = CGRectMake(0, buttom + PostItemGapF, width, CGFloat(ceilf(Float(height))))
            buttom += (height + PostItemGapF)
        }
        else {
            m_article.hidden = true
        }
        
        if m_post?.m_imgUrls.count > 0 {
            let height = (width - PostItemGapF*2) / 3
            m_previews.hidden = false
            m_previews.frame = CGRectMake(0, buttom + PostItemGapF, width, height)
            m_previews.reload(m_post!)
            buttom += (height + PostItemGapF)
        }
        else {
            m_previews.hidden = true
        }
        
        if fullView {
            m_commentBtn.hidden = false
            m_commentBtn.frame = CGRectMake(self.frame.width - PostPhotoSize, buttom + PostItemGapF, PostBtnSize, PostBtnSize)
            m_liktBtn.hidden = false
            m_liktBtn.frame = CGRectMake(self.frame.width - PostPhotoSize - 50, buttom + PostItemGapF, PostBtnSize, PostBtnSize)
            m_deleteBtn.hidden = !selfPost
            m_deleteBtn.frame = CGRectMake(self.frame.width - PostPhotoSize - 100, buttom + PostItemGapF, PostBtnSize, PostBtnSize)
        }
        else {
            m_commentBtn.hidden = true
            m_liktBtn.hidden = true
            m_deleteBtn.hidden = true
        }
    }
}
