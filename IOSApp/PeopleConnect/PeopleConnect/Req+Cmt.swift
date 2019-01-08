//
//  Requests+Cmt.swift
//  PeopleConnect
//
//  Created by apple on 18/12/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func addComment(post:Post, cmtObjs:[AnyObject]) {
    // add comments
    for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
        if let cmt = CommentInfo(json: cmtObj) {
            post.m_comments.append(cmt)
        }
    }
}

func httpAddComment(post:Post, to:UInt64, src:UInt32, cmt:String) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: to),
        "oid":NSNumber(unsignedLongLong: post.m_info.user),
        "pid":NSNumber(unsignedLongLong: post.m_info.id),
        "cmt":cmt,
        "src":NSNumber(unsignedInt: src),
        "last":NSNumber(unsignedLongLong: (post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))]
    http.postRequest("comment", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let subData = processErrorCode(response as! NSData, failed: nil)
            if subData != nil {
                if let json = getJson(subData!) {
                    if let cmtObjs = json["cmt"] as? [AnyObject] {
                        addComment(post, cmtObjs: cmtObjs)
                    }
                    
                    if let id = json["cid"] as? NSNumber {
                        var newComment = CommentInfo()
                        newComment.from = userInfo.userID
                        newComment.to   = to
                        newComment.id   = id.unsignedLongLongValue
                        newComment.cmt  = cmt
                        newComment.src  = src
                        post.m_comments.append(newComment)
                        post.m_father?.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpDelComment(post:Post, cmt:CommentInfo) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "cid":NSNumber(unsignedLongLong: cmt.id),
        "oid":NSNumber(unsignedLongLong: post.m_info.user),
        "pid":NSNumber(unsignedLongLong: post.m_info.id)]
    http.postRequest("delcmt", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                for (idx, comment) in post.m_comments.enumerate() {
                    if comment.id == cmt.id && comment.from == cmt.from {
                        post.m_comments.removeAtIndex(idx)
                        break
                    }
                }
                post.m_father?.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpUpdateComments() {
}

func httpLikePost(post:Post, btn:UIButton) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "oid":NSNumber(unsignedLongLong: post.m_info.user),
        "pid":NSNumber(unsignedLongLong: post.m_info.id),
        "like":NSNumber(bool: !post.m_info.liked)]
    http.postRequest("likepost", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                post.m_info.liked = !post.m_info.liked
                btn.highlighted = post.m_info.liked
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}
