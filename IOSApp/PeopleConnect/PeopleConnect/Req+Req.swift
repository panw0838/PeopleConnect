//
//  Req+Req.swift
//  PeopleConnect
//
//  Created by apple on 19/2/1.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

func httpRequestContact(contact:UInt64, messege:String) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: contact),
        "mess":messege]
    http.postRequest("requestcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                tcp.notifyMessege(contact)
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpAcceptRequest(contact:UInt64) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "contact":NSNumber(unsignedLongLong: contact)]
    http.postRequest("acceptrequest", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                let cInfo = contactsData.getUser(contact)
                contactsData.addContact(ContactInfo(id: contact, f: UndefineBit, n: cInfo!.name))
                contactsData.updateDelegates()
                
                reqNotify!.remRequest(contact)
                reqNotify!.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpDeclineRequest(contact:UInt64) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cid":NSNumber(unsignedLongLong: contact)]
    http.postRequest("declinerequest", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                reqNotify!.remRequest(contact)
                reqNotify!.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncRequests() {
    reqNotify!.m_requests.removeAll()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncrequests", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let jsonData = processErrorCode(response as! NSData, failed: nil)
            if jsonData != nil {
                if let json = getJson(jsonData!) {
                    if let reqObjs = json["requests"] as? [AnyObject] {
                        for case let reqObj in (reqObjs as? [[String:AnyObject]])! {
                            if let request = RequestInfo(json: reqObj) {
                                contactsData.addUser(request.from, name: request.name, flag: 0)
                                reqNotify!.addRequest(request)
                            }
                        }
                        
                        contactsData.getUsers(
                            {()->Void in
                                reqNotify!.UpdateDelegate()
                            },
                            failed: nil)
                        
                        reqNotify?.m_messages.removeAll()
                        reqNotify?.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

