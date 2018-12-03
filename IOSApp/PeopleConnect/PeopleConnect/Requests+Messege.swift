//
//  MessegeRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpSyncRequests() {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncrequests", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                    if let requestObjs = json["requests"] as? [AnyObject] {
                        for case let requestObj in (requestObjs as? [[String:AnyObject]])! {
                            if let request = RequestInfo(json: requestObj) {
                                messegeData.AddNewRequest(request)
                            }
                        }
                    }
                    for callback in messegeCallbacks {
                        callback.MessegeUpdateUI()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpSendMessege(to:UInt64, messege:String) {
    let params: Dictionary = ["from":NSNumber(unsignedLongLong: userInfo.userID), "to":NSNumber(unsignedLongLong: to), "msg":messege]
    http.postRequest("sendmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                tcp.notifyMessege(to)
                var selfMessege = MessegeInfo()
                selfMessege.from = userInfo.userID
                selfMessege.time = 0
                selfMessege.data = messege
                selfMessege.type = .String
                messegeData.AddNewMessege(to, newMessege: selfMessege)
                for callback in messegeCallbacks {
                    callback.MessegeUpdateUI()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpSyncMessege() {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "sync":NSNumber(unsignedInt: 1)]
    http.postRequest("syncmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                    if let messObjs = json["mess"] as? [AnyObject] {
                        for case let messObj in (messObjs as? [[String:AnyObject]])! {
                            if let messege = MessegeInfo(json: messObj) {
                                messegeData.AddNewMessege(messege.from, newMessege: messege)
                            }
                        }
                        for callback in messegeCallbacks {
                            callback.MessegeUpdateUI()
                        }
                    }
                    let newSyncID:UInt = (UInt)((json["sync"]?.integerValue)!)
                    print("fff")
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}
