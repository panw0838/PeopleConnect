//
//  View+PostHeader.swift
//  PeopleConnect
//
//  Created by apple on 18/12/12.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PostHeader: UITableViewHeaderFooterView {
    
    //@IBOutlet weak var m_profile: UIImageView!
    //@IBOutlet weak var m_name: UILabel!
    //@IBOutlet weak var m_article: UILabel!
    //@IBOutlet weak var m_previews: ImgPreview!
    //@IBOutlet weak var m_liktBtn: UIButton!
    
    var m_profile    = UIImageView(frame: CGRectZero)
    var m_name       = UILabel(frame: CGRectZero)
    
    var m_showAllBtn = UIButton(frame: CGRectZero)
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
        m_profile.contentMode = .ScaleAspectFill;
        m_profile.userInteractionEnabled = true;
        m_profile.layer.masksToBounds = true;
        self.addSubview(m_profile)
        
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
        
        m_article.lineBreakMode = .ByCharWrapping
        m_article.numberOfLines = 0
        self.addSubview(m_article)
        
        self.addSubview(m_previews)
        
        m_liktBtn.setImage(UIImage(named: "comment_like"), forState: .Normal)
        self.addSubview(m_liktBtn)
        
        m_commentBtn.setImage(UIImage(named: "comment_cmt"), forState: .Normal)
        m_commentBtn.addTarget(self, action: Selector("actComment:"), forControlEvents: .TouchDown)
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
        var buttom:CGFloat = 0.0
        let contact = contactsData.getContact((m_post?.m_info.user)!)
        
        m_profile.image = UIImage(named: "default_profile")
        m_profile.frame = CGRectMake(0, 0, 40, 40)
        buttom = 40.0
        
        m_name.text = contact?.name
        m_name.frame = CGRectMake(45, 0, 100, 20)
        
        if m_post?.m_info.content.characters.count > 0 {
            let height = getTextHeight(post.m_info.content, width: self.frame.width, font: articleFont)
            m_article.text = m_post?.m_info.content
            m_article.hidden = false
            m_article.sizeToFit()
            m_article.frame = CGRectMake(0, buttom + PostItemGapF, self.frame.width, height)
            buttom += (height + PostItemGapF)
        }
        else {
            m_article.hidden = true
        }
        
        if m_post?.m_imgUrls.count > 0 {
            let height = (self.frame.width - PostItemGapF) / 2
            m_previews.hidden = false
            m_previews.frame = CGRectMake(0, buttom + PostItemGapF, self.frame.width, height)
            m_previews.reload(m_post!)
            buttom += (height + PostItemGapF)
        }
        else {
            m_previews.hidden = true
        }
        
        m_commentBtn.frame = CGRectMake(self.frame.width - 30, buttom + PostItemGapF, 20, 20)
        m_liktBtn.frame = CGRectMake(self.frame.width - 80, buttom + PostItemGapF, 20, 20)
    }
}
