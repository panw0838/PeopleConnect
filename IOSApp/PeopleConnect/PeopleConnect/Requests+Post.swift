//
//  Requests+Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/26.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func httpSendPost(flag:UInt64, desc:String, files:Array<String>) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "flag":NSNumber(unsignedLongLong: flag), "desc":desc]
    http.postDataRequest("sendmessege", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            let data = NSData(contentsOfFile: files[0])
            formData.appendPartWithFileData(data!, name: "", fileName: "", mimeType: "image/jpeg")
            //UIImage *image = headImage[i];
            //NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
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
