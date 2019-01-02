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
                msgData.remRequest(contact)
                msgData.UpdateRequestsDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncRequests() {
    msgData.m_requests.removeAll()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncrequests", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let reqData = processErrorCode(response as! NSData, failed: nil)
            if reqData != nil {
                if let json = getJson(reqData!) {
                    if let reqObjs = json["requests"] as? [AnyObject] {
                        var ids = Array<UInt64>()
                        for case let reqObj in (reqObjs as? [[String:AnyObject]])! {
                            if let request = RequestInfo(json: reqObj) {
                                let newContact = ContactInfo(id: request.from, f: 0, n: request.name)
                                contactsData.addUser(newContact)
                                msgData.m_requests.append(request)
                                ids.append(request.from)
                            }
                        }
                        
                        let photoList = getPhotoMissingList(ids)
                        if photoList.count > 0 {
                            httpGetPhotos(photoList,
                                passed: {()->Void in
                                    msgData.UpdateRequestsDelegate()
                                },
                                failed: nil)                            
                        }

                        msgData.UpdateRequestsDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpSendMessege(to:UInt64, messege:String) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: to),
        "msg":messege,
        "type":NSNumber(integer: MessegeType.Msg_Str.rawValue)]
    http.postRequest("sendmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                tcp.notifyMessege(to)
                var selfMessege = MsgInfo()
                selfMessege.from = userInfo.userID
                selfMessege.time = 0
                selfMessege.data = messege
                selfMessege.type = .Msg_Str
                msgData.AddNewMsg(selfMessege)
                msgData.getConversation(to).UpdateDelegate()
                msgData.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        })
}

func httpSyncMessege(passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "sync":NSNumber(unsignedLongLong: userInfo.msgSyncID)]
    http.postRequest("syncmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let msgJson = processErrorCode(response as! NSData, failed: failed)
            if msgJson != nil {
                if let json = getJson(msgJson!) {
                    if let messObjs = json["mess"] as? [AnyObject] {
                        for case let messObj in (messObjs as? [[String:AnyObject]])! {
                            if let msg = MsgInfo(json: messObj) {
                                msgData.AddNewMsg(msg)
                                
                                // process notifications
                                if msg.type == .Ntf_Add {
                                    var contact = contactsData.m_contacts[msg.from]
                                    if contact?.flag == 0 {
                                        contact?.flag = UndefineBit
                                        contactsData.m_contacts[msg.from] = contact
                                        contactsData.updateDelegates()
                                    }
                                }
                                
                                if msg.type == .Ntf_New {
                                    friendPosts.m_needSync = true
                                }
                                if msg.type == .Ntf_Lik {
                                    selfPosts.m_needSync = true
                                }
                                if msg.type == .Ntf_Cmt {
                                    if msg.oID == userInfo.userID {
                                        selfPosts.m_needSync = true
                                    }
                                    else {
                                        if msg.src == FriPosts {
                                            friendPosts.m_needSync = true
                                        }
                                        else if msg.src == StrPosts {
                                            nearPosts.m_needSync = true
                                        }
                                        else {
                                            let groupPosts = groupsPosts[msg.src]
                                            groupPosts?.m_needSync = true
                                        }
                                    }
                                }
                            }
                        }
                        msgData.UpdateDelegate()
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


