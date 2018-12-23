//
//  MessegeRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpSyncRequests(passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncrequests", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let reqData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                if let json = try? NSJSONSerialization.JSONObjectWithData(reqData, options: .MutableContainers) as! [String:AnyObject] {
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
                passed?()
            }
            else {
                failed?(httpErrMsg[errCode])
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
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

func httpSyncMessege(passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "sync":NSNumber(unsignedLongLong: 0)]
    http.postRequest("syncmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let msgData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                if let json = try? NSJSONSerialization.JSONObjectWithData(msgData, options: .MutableContainers) as! [String:AnyObject] {
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
                    let newSyncID:UInt64 = (UInt64)((json["sync"]?.integerValue)!)
                    print("fff")
                }
                passed?()
            }
            else {
                failed?(httpErrMsg[errCode])
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}
