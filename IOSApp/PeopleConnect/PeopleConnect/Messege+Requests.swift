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
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpAddContact(contact:UInt64, flag:UInt64, name:String) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "contact":NSNumber(unsignedLongLong: contact), "name":name, "flag":NSNumber(unsignedLongLong: flag)]
    http.postRequest("addcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                contactsData.addContact(ContactInfo(id: contact, f: flag, n: name))
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

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
                    if let tagObjs = json["mess"] as? [AnyObject] {
                        for case let tagObj in (tagObjs as? [[String:AnyObject]])! {
                            if let messege = MessegeInfo(json: tagObj) {
                                messegeData.AddNewMessege(messege)
                            }
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
