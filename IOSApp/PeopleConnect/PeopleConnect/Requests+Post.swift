//
//  Requests+Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/26.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func getSnapshotUrl(cID:UInt64, pID:UInt64, fileName:String)->String {
    return String(cID) + "/" + String(pID) + "/snap_" + fileName
}

func getFileUrl(cID:UInt64, pID:UInt64, fileName:String)->String {
    return String(cID) + "/" + String(pID) + "/" + fileName
}

func httpSendPost(flag:UInt64, desc:String, datas:Array<NSData>) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "flag":NSNumber(unsignedLongLong: flag), "desc":desc]
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
                            }
                        }
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

func httpGetSnapshot() {
    
}

func httpCommentPost() {
    
}

func httpLikePost() {
    
}
