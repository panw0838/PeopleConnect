//
//  MessegeRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpSendMessege(to:UInt64, messege:String) {
    let params: Dictionary = ["from":NSNumber(unsignedLongLong: userInfo.userID), "to":NSNumber(unsignedLongLong: to), "mess":messege]
    http.postRequest("sendmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpSyncMessege() {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                    var messeges:Array<MessegeInfo> = Array<MessegeInfo>()
                    
                    if let tagObjs = json["mess"] as? [AnyObject] {
                        for case let tagObj in (tagObjs as? [[String:AnyObject]])! {
                            if let messege = MessegeInfo(json: tagObj) {
                                messeges.append(messege)
                            }
                        }
                        messegeData.AddNewMesseges(messeges)
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}