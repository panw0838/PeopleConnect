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
    var m_showPhoto:Bool = true
    var m_showMsg: Bool = true
    
    func setTable(table:UITableView, data:PostData, showPhoto: Bool, showMsg: Bool) {
        m_data = data
        m_data?.setDelegate(self)
        
        m_table = table
        m_table!.registerClass(PostHeader.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostHeader")
        m_table!.registerClass(PostFooter.classForCoder(), forHeaderFooterViewReuseIdentifier: "PostFooter")
        m_table!.estimatedRowHeight = 16
        m_table!.rowHeight = UITableViewAutomaticDimension
        
        m_showPhoto = showPhoto
        m_showMsg = showMsg
    }
    
    func PostDataUpdated() {
        m_table!.reloadData()
    }
    
    func commentChanged(sender:UITextField) {
        let alert:UIAlertController = self.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let len = input.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (len > 0 && len < 50)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return m_data!.numOfPosts()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !m_showMsg {
            return 0
        }
        return m_data!.postAtIdx(section).m_comments.count + (m_data?.m_sorce == 0 ? 1 : 0)
    }
    
    func setupLikeCell(cell:CommentCell, post:Post) {
        var str:String = "[❤]"
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        var ranges = Array<String>()
        
        for cID in post.m_info.likes {
            let name = contactsData.m_contacts[cID]?.name
            
            if name != nil {
                let range = NSMakeRange(str.characters.count, (name?.characters.count)! + 2)
                str += " " + name! + " "
                ranges.append(NSStringFromRange(range))
            }
        }
        
        let attStr = NSMutableAttributedString(string: str)
        attStr.setAttributes(attDic, range: NSMakeRange(0, str.characters.count))
        attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, 3))
        
        for range in ranges {
            attStr.addAttribute(NSForegroundColorAttributeName, value: linkTextColor, range: NSRangeFromString(range))
        }
        
        cell.m_comment.attributedText = attStr
        
        cell.m_comment.yb_addAttributeTapActionWithRanges(ranges,
            tapClicked: { (UILabel, NSString, NSRange, i:Int)->Void in
                ContactView.ContactID = post.m_info.likes[i]
                self.performSegueWithIdentifier("ShowContact", sender: self)
        })
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
    
    
    func setupCommentCell(cell:CommentCell, isSelf:Bool, post:Post, comment:CommentInfo) {
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
        let toRange = NSMakeRange(fromRange.location + fromRange.length + 1, toName.characters.count)
        let toColor = (comment.to == userInfo.userID ? selfTextColor : linkTextColor)
        var cmtRange = NSMakeRange(fromRange.location+fromRange.length+1, comment.cmt.characters.count)
        
        attStr.addAttribute(NSForegroundColorAttributeName, value: fromColor, range: fromRange)
        if comment.to != 0 {
            attStr.addAttribute(NSForegroundColorAttributeName, value: toColor, range: toRange)
        }
        
        cell.m_comment.attributedText = attStr
        var ranges = Array<String>()
        var commands = Array<Int>()
        
        if comment.from != userInfo.userID {
            ranges.append(fromName)
            commands.append(0)
        }
        
        if comment.to != 0 && comment.to != userInfo.userID {
            cmtRange.location = toRange.location + toRange.length + 1
            ranges.append(toName)
            commands.append(1)
        }
        
        ranges.append(comment.cmt)
        commands.append(2)
        
        cell.m_comment.yb_addAttributeTapActionWithStrings(ranges,
            tapClicked: { (UILabel, NSString, NSRange, i:NSInteger)->Void in
                if commands[i] == 2 {
                    self.tapComment(isSelf, post: post, comment: comment)
                }
                else {
                    ContactView.ContactID = (commands[i] == 0 ? comment.from : comment.to)
                    self.performSegueWithIdentifier("ShowContact", sender: self)
                }
        })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        let post = m_data!.postAtIdx(indexPath.section)
        let isSelf = m_data?.m_sorce == 0
        
        if isSelf {
            if indexPath.row == 0 {
                setupLikeCell(cell, post: post)
            }
            else {
                let comment = post.m_comments[indexPath.row - 1]
                setupCommentCell(cell, isSelf: isSelf, post: post, comment: comment)
            }
        }
        else {
            let comment = post.m_comments[indexPath.row]
            setupCommentCell(cell, isSelf: isSelf, post: post, comment: comment)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("PostHeader") as! PostHeader
        let post = m_data!.postAtIdx(section)
        header.m_father = self
        header.reload(post, data: m_data!, width:m_table!.contentSize.width, showPhoto: m_showPhoto, showTool: m_showMsg)
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
        return post.getHeight(m_table!.contentSize.width, showPhoto: m_showPhoto, showTool: m_showMsg)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PostFooter.Height
    }
}
