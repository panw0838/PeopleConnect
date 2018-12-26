//
//  Requests+Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/26.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func getFileUrl(cID:UInt64, pID:UInt64, fileName:String)->String {
    return String(cID) + "/" + String(pID) + "/" + fileName
}

func httpSendPost(flag:UInt64, desc:String, datas:Array<NSData>, groups:Array<UInt32>, nearby:Bool) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "flag":NSNumber(unsignedLongLong: flag),
        "cont":desc,
        "X":NSNumber(double: userInfo.x),
        "Y":NSNumber(double: userInfo.y),
        "group":http.getUInt32ArrayParam(groups),
        "near":NSNumber(bool: nearby)]
    http.postDataRequest("newpost", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            for (idx, data) in datas.enumerate() {
                formData.appendPartWithFileData(data, name:String(idx), fileName:String(idx), mimeType: "image/jpeg")
            }
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let retData = processErrorCode(response as! NSData, failed: nil)
            if retData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(retData!, options: .MutableContainers) {
                    let dict: NSDictionary = json as! NSDictionary
                    let pID = (UInt64)((dict["post"]?.unsignedLongLongValue)!)
                    print("%d", pID)
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpDeletePost() {
    
}

func httpSyncPost() {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "post":NSNumber(unsignedLongLong: 0)]
    http.postRequest("syncposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        for case let postObj in (postObjs as? [[String:AnyObject]])! {
                            if let post = PostInfo(json: postObj) {
                                friendPosts.AddPost(post)
                                // add comments
                                if let cmtObjs = postObj["cmt"] as? [AnyObject] {
                                    for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                                        if let cmt = CommentInfo(json: cmtObj) {
                                            friendPosts.m_posts.last?.m_comments.append(cmt)
                                        }
                                    }
                                }
                            }
                        }
                        friendPosts.getPreviews()
                        friendPosts.Update()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncContactPost(cID:UInt64) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "cid":NSNumber(unsignedLongLong: cID)]
    
    contactPosts.clear()

    http.postRequest("synccontactposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(postsData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        for case let postObj in (postObjs as? [[String:AnyObject]])! {
                            if let post = PostInfo(json: postObj) {
                                contactPosts.AddPost(post)
                                // add comments
                                if let cmtObjs = postObj["cmt"] as? [AnyObject] {
                                    for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                                        if let cmt = CommentInfo(json: cmtObj) {
                                            contactPosts.m_posts.last?.m_comments.append(cmt)
                                        }
                                    }
                                }
                            }
                        }
                        contactPosts.getPreviews()
                        contactPosts.Update()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncNearbyPost() {
    let params: Dictionary = [
        "x":NSNumber(double: userInfo.x),
        "y":NSNumber(double: userInfo.y)]
    http.postRequest("syncnearbyposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(postsData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        for case let postObj in (postObjs as? [[String:AnyObject]])! {
                            if let post = PostInfo(json: postObj) {
                                nearPosts.AddPost(post)
                                // add comments
                                if let cmtObjs = postObj["cmt"] as? [AnyObject] {
                                    for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                                        if let cmt = CommentInfo(json: cmtObj) {
                                            nearPosts.m_posts.last?.m_comments.append(cmt)
                                        }
                                    }
                                }
                            }
                        }
                        nearPosts.getPreviews()
                        nearPosts.Update()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpGetSnapshots(files:Array<String>, delegate:PostDataDelegate?) {
    let fileParam = http.getStringArrayParam(files)
    let params: Dictionary = ["files":fileParam]
    http.postRequest("previews", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let previewsData = processErrorCode(response as! NSData, failed: nil)
            if previewsData != nil {
                let subDatas = splitData(previewsData!)
                for (i, file) in files.enumerate() {
                    setPostPreview(file, data: subDatas[i])
                    previews[file] = UIImage(data: subDatas[i])
                }
            }
            delegate?.PostDataUpdated()
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

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
