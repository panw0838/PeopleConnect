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
        return m_fullView ? m_data!.postAtIdx(section).m_comments.count : 0
    }
    
    func tapComment(post:Post, comment:CommentInfo) {
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = m_data!.postAtIdx(indexPath.section)
        let comment = post.m_comments[indexPath.row]
        let isSelf = m_data?.m_sorce == 0
        
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

        cell.m_comment.attributedText = attStr
        
        if comment.from != userInfo.userID {
            cell.m_comment.yb_addAttributeTapActionWithRanges([NSStringFromRange(fromRange)],
                tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                    ContactView.ContactID = comment.from
                    self.performSegueWithIdentifier("ShowContact", sender: self)
            })
        }
        
        if comment.to != 0 && comment.to != userInfo.userID {
            cmtRange.location = toRange.location + toRange.length + 1
            cell.m_comment.yb_addAttributeTapActionWithRanges([NSStringFromRange(toRange)],
                tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                    ContactView.ContactID = comment.to
                    self.performSegueWithIdentifier("ShowContact", sender: self)
            })
        }
        
        cell.m_comment.yb_addAttributeTapActionWithRanges([NSStringFromRange(cmtRange)],
            tapClicked: { (UILabel, NSString, NSRange, NSInteger)->Void in
                self.tapComment(post, comment: comment)
        })
        
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
        return getTextHeight(comment.getString(m_data?.m_sorce == 0), width: m_table!.contentSize.width, font: commentFont)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = m_data!.postAtIdx(section)
        return post.getHeight(m_table!.contentSize.width, fullView: m_fullView)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
}
