//
//  MessegeRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpRequestContact(contact:UInt64, name:String, messege:String) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: contact),
        "name":name,
        "mess":messege]
    http.postRequest("requestcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) != 0 {
                print("请求失败")
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
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

func httpGetLikeUsers() {
    likeNotify?.m_likers.removeAll()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("getlikemeusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let usersObjs = json["users"] as? [AnyObject] {
                        for case let userObj in (usersObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: userObj) {
                                likeNotify?.addLiker(contact.user)
                                contactsData.addUser(contact.user, name: "", flag: 0)
                            }
                        }
                        
                        contactsData.getUsers(
                            {()->Void in
                                likeNotify!.UpdateDelegate()
                            },
                            failed: nil)
                        likeNotify!.UpdateDelegate()
                        
                    }
                    likeNotify?.m_messages.removeAll()
                    likeNotify?.UpdateDelegate()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpSendMessege(to:UInt64, messege:String, passed:((UInt64)->Void)?, failed:(()->Void)?) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: to),
        "msg":messege,
        "type":NSNumber(integer: MessegeType.Msg_Str.rawValue)]
    let handler = contactsData.getUser(to)!.flag == 0 ? "sendsmsg" : "sendfmsg"
    http.postRequest(handler, params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if let retData = processErrorCode(response as! NSData, failed: nil) {
                if let json = getJson(retData) {
                    tcp.notifyMessege(to)
                    passed?(UInt64(json["id"]!.unsignedLongLongValue))
                    return
                }
            }
            failed?()
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?()
        })
}

func httpSyncMessege(passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "sync":NSNumber(unsignedLongLong: userInfo.msgSyncID)]
    http.postRequest("syncmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if let msgJson = processErrorCode(response as! NSData, failed: failed) {
                if let json = getJson(msgJson) {
                    if let messObjs = json["mess"] as? [AnyObject] {
                        var ids = Array<UInt64>()
                        for case let messObj in (messObjs as? [[String:AnyObject]])! {
                            if let msg = MsgInfo(json: messObj) {
                                msgData.AddNewMsg(msg)
                                ids.append(msg.from)
                            }
                        }
                        msgData.UpdateDelegate()
                        
                        let photoList = getPhotoMissingList(ids)
                        if photoList.count > 0 {
                            httpGetPhotos(photoList,
                                passed: {()->Void in
                                    msgData.UpdateDelegate()
                                },
                                failed: nil)
                        }
                    }
                    let newSyncID = (UInt64)((json["sync"]?.unsignedLongLongValue)!)
                    userData.setMsgSyncID(newSyncID)
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}


