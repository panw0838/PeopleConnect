//
//  Requests+Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/26.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

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
    
}

func httpCommentPost() {
    
}

func httpLikePost() {
    
}
