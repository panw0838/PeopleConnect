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
    
    var m_father:PostsTable?
    
    func setupLikeComment(post:Post) {
        var str:String = "[❤]"
        let attStr = NSMutableAttributedString(string: str)
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        var ranges = Array<String>()
        
        for cID in post.m_info.likes {
            let name = contactsData.m_contacts[cID]?.name
            
            if name != nil {
                let range = NSMakeRange(str.characters.count+1, (name?.characters.count)!)
                str += " " + name!
                ranges.append(NSStringFromRange(range))
            }
        }
        
        attStr.setAttributes(attDic, range: NSMakeRange(0, str.characters.count))
        attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, 3))
        
        for range in ranges {
            attStr.addAttribute(NSForegroundColorAttributeName, value: linkTextColor, range: NSRangeFromString(range))
        }

        self.m_comment.attributedText = attStr
        
        self.m_comment.yb_addAttributeTapActionWithRanges(ranges,
            tapClicked: { (UILabel, NSString, NSRange, i:Int)->Void in
                ContactView.ContactID = post.m_info.likes[i]
                self.m_father?.performSegueWithIdentifier("ShowContact", sender: self)
        })
    }
    
    func setupComment(isSelf:Bool, post:Post, comment:CommentInfo) {
        let offset = isSelf ? 4 : 0
        let fromName = comment.getUserName(comment.from)
        let toName   = comment.getUserName(comment.to)
        
        let str = comment.getString(isSelf)
        let attStr = NSMutableAttributedString(string: str)
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        
        attStr.setAttributes(attDic, range: NSMakeRange(0, str.characters.count))
        
        if isSelf {
            attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, 4))
        }
        
        let fromRange = NSMakeRange(offset, fromName.characters.count)
        let fromColor = (comment.from == userInfo.userID ? selfTextColor : linkTextColor)
        let toRange = NSMakeRange(fromRange.location + fromRange.length + 3, toName.characters.count)
        let toColor = (comment.to == userInfo.userID ? selfTextColor : linkTextColor)
        var cmtRange = NSMakeRange(fromRange.location+fromRange.length+1, comment.cmt.characters.count)
        
        attStr.addAttribute(NSForegroundColorAttributeName, value: fromColor, range: fromRange)
        if comment.to != 0 {
            attStr.addAttribute(NSForegroundColorAttributeName, value: toColor, range: toRange)
        }
        
        self.m_comment.attributedText = attStr
        
        if comment.from != userInfo.userID {
            self.m_comment.yb_addAttributeTapActionWithRanges([NSStringFromRange(fromRange)],
                tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                    ContactView.ContactID = comment.from
                    self.m_father?.performSegueWithIdentifier("ShowContact", sender: self)
            })
        }
        
        if comment.to != 0 && comment.to != userInfo.userID {
            cmtRange.location = toRange.location + toRange.length + 1
            self.m_comment.yb_addAttributeTapActionWithRanges([NSStringFromRange(toRange)],
                tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                    ContactView.ContactID = comment.to
                    self.m_father?.performSegueWithIdentifier("ShowContact", sender: self)
            })
        }
        
        self.m_comment.yb_addAttributeTapActionWithStrings([comment.cmt],
            tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                self.m_father?.tapComment(isSelf, post: post, comment: comment)
        })
    }
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
    
    func tapComment(isSelf:Bool, post:Post, comment:CommentInfo) {
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
                    let src = (self.m_data?.m_sorce != 0 ? (self.m_data?.m_sorce)! : comment.src)
                    httpAddComment(post, to: (comment.from), src: src, cmt: (alert.textFields?.first?.text)!)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return m_data!.numOfPosts()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !m_fullView {
            return 0
        }
        return m_data!.postAtIdx(section).m_comments.count + (m_data?.m_sorce == 0 ? 1 : 0)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = m_data!.postAtIdx(indexPath.section)
        let isSelf = m_data?.m_sorce == 0
        
        cell.m_father = self
        
        if isSelf {
            if indexPath.row == 0 {
                cell.setupLikeComment(post)
            }
            else {
                let comment = post.m_comments[indexPath.row - 1]
                cell.setupComment(isSelf, post: post, comment: comment)
            }
        }
        else {
            let comment = post.m_comments[indexPath.row]
            cell.setupComment(isSelf, post: post, comment: comment)
        }
        
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
        let width = m_table!.contentSize.width
        let isSelf = m_data?.m_sorce == 0
        
        if isSelf {
            if indexPath.row == 0 {
                let likeStr = post.getLikeString()
                return getTextHeight(likeStr, width: width, font: commentFont)
            }
            else {
                let comment = post.m_comments[indexPath.row - 1]
                return getTextHeight(comment.getString(isSelf), width: width, font: commentFont)
            }
        }
        else {
            let comment = post.m_comments[indexPath.row]
            return getTextHeight(comment.getString(isSelf), width: width, font: commentFont)
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = m_data!.postAtIdx(section)
        return post.getHeight(m_table!.contentSize.width, fullView: m_fullView)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
}
