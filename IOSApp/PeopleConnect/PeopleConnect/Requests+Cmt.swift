//
//  Requests+Cmt.swift
//  PeopleConnect
//
//  Created by apple on 18/12/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func httpAddComment(post:Post, to:UInt64, pub:UInt8, cmt:String) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: to),
        "pub":NSNumber(unsignedChar: pub),
        "oid":NSNumber(unsignedLongLong: post.m_info.user),
        "pid":NSNumber(unsignedLongLong: post.m_info.id),
        "last":NSNumber(unsignedLongLong: (post.m_comments.count == 0 ? 0 : (post.m_comments.last?.id)!)),
        "cmt":cmt]
    http.postRequest("comment", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let subData = processErrorCode(response as! NSData, failed: nil)
            if subData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(subData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let cmtObjs = json["cmts"] as? [AnyObject] {
                        for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                            if let comment = CommentInfo(json: cmtObj) {
                                post.m_comments.append(comment)
                            }
                        }
                    }
                    if let id = json["cid"] as? NSNumber {
                        var newComment = CommentInfo()
                        newComment.from = userInfo.userID
                        newComment.to   = to
                        newComment.id   = id.unsignedLongLongValue
                        newComment.cmt  = cmt
                        post.m_comments.append(newComment)
                    }
                    
                    friendPosts.Update()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpDelComment(post:Post, cmt:CommentInfo, pub:UInt8) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "cid":NSNumber(unsignedLongLong: cmt.id),
        "pub":NSNumber(unsignedChar: pub),
        "oid":NSNumber(unsignedLongLong: post.m_info.user),
        "pid":NSNumber(unsignedLongLong: post.m_info.id),
        "last":NSNumber(unsignedLongLong: (post.m_comments.count == 0 ? 0 : (post.m_comments.last?.id)!))]
    http.postRequest("delcmt", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let subData = processErrorCode(response as! NSData, failed: nil)
            if subData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(subData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let cmtObjs = json["cmts"] as? [AnyObject] {
                        for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                            if let comment = CommentInfo(json: cmtObj) {
                                post.m_comments.append(comment)
                            }
                        }
                    }
                    
                    for (idx, comment) in post.m_comments.enumerate() {
                        if comment.id == cmt.id && comment.from == cmt.from {
                            post.m_comments.removeAtIndex(idx)
                        }
                    }
                    
                    friendPosts.Update()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpUpdateComments() {
}

func httpLikePost() {
    
}
