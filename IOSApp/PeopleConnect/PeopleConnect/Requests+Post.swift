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

func httpCommentPost() {
    
}

func httpLikePost() {
    
}
