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

func httpSendPost(flag:UInt64, desc:String, datas:Array<NSData>) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "flag":NSNumber(unsignedLongLong: flag), "cont":desc]
    http.postDataRequest("newpost", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            for (idx, data) in datas.enumerate() {
                formData.appendPartWithFileData(data, name:String(idx), fileName:String(idx), mimeType: "image/jpeg")
            }
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    let pID:UInt64 = (UInt64)((dict["post"]?.integerValue)!)
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
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "post":NSNumber(unsignedLongLong: 0)]
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
                                postData.AddPost(post)
                                // add comments
                                if let cmtObjs = postObj["cmt"] as? [AnyObject] {
                                    for case let cmtObj in (cmtObjs as? [[String:AnyObject]])! {
                                        if let cmt = CommentInfo(json: cmtObj) {
                                            postData.m_posts.last?.m_comments.append(cmt)
                                        }
                                    }
                                }
                            }
                        }
                        postData.getPreviews()
                        for callback in postCallbacks {
                            callback.PostUpdateUI()
                        }
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpGetSnapshots(files:Array<String>) {
    let fileParam = http.getStringArrayParam(files)
    let params: Dictionary = ["files":fileParam]
    http.postRequest("previews", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let previewsData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                let subDatas = splitData(previewsData)
                for (i, file) in files.enumerate() {
                    let image = UIImage(data: subDatas[i])
                    postData.m_snaps[file] = image
                }
                for callback in postCallbacks {
                    callback.PostUpdateUI()
                }
            }
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
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let subData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                if let json = try? NSJSONSerialization.JSONObjectWithData(subData, options: .MutableContainers) as! [String:AnyObject] {
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
                        newComment.to   = post.m_info.user
                        newComment.id   = id.unsignedLongLongValue
                        newComment.cmt  = cmt
                        post.m_comments.append(newComment)
                    }

                    post.updateGeometry()
                    
                    for callback in postCallbacks {
                        callback.PostUpdateUI()
                    }
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
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let subData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                if let json = try? NSJSONSerialization.JSONObjectWithData(subData, options: .MutableContainers) as! [String:AnyObject] {
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
                    
                    post.updateGeometry()
                    
                    for callback in postCallbacks {
                        callback.PostUpdateUI()
                    }
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
