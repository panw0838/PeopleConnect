//
//  MessegeRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpRequestContact(contact:UInt64, flag:UInt64, name:String, messege:String) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: contact),
        "name":name,
        "flag":NSNumber(unsignedLongLong: flag),
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

func httpSyncRequests(passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("syncrequests", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let reqData = processErrorCode(response as! NSData, failed: failed)
            if reqData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(reqData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let requestObjs = json["requests"] as? [AnyObject] {
                        var photoIDs = Array<UInt64>()
                        for case let requestObj in (requestObjs as? [[String:AnyObject]])! {
                            if let request = RequestInfo(json: requestObj) {
                                var msg = MsgInfo()
                                msg.from = request.from
                                msg.name = request.name
                                msg.type = .Request
                                msg.data = request.messege
                                msg.time = 0
                                msgData.AddNewMsg(msg.from, newMsg: msg)
                                if contactsData.getPhoto(request.from) == nil {
                                    photoIDs.append(request.from)
                                }
                            }
                        }
                        if photoIDs.count > 0 {
                            httpGetMsgsPhotos(photoIDs)
                        }
                        msgData.UpdateDelegates()
                    }
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
    })
}

func httpSendMessege(to:UInt64, messege:String) {
    let params: Dictionary = [
        "from":NSNumber(unsignedLongLong: userInfo.userID),
        "to":NSNumber(unsignedLongLong: to),
        "msg":messege,
        "type":NSNumber(integer: MessegeType.String.rawValue)]
    http.postRequest("sendmessege", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                tcp.notifyMessege(to)
                var selfMessege = MsgInfo()
                selfMessege.from = userInfo.userID
                selfMessege.time = 0
                selfMessege.data = messege
                selfMessege.type = .String
                msgData.AddNewMsg(to, newMsg: selfMessege)
                msgData.m_rawData.append(MsgInfoCoder(info: selfMessege))
                msgData.saveMsgToCache()
                msgData.UpdateDelegates()
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
                if let json = try? NSJSONSerialization.JSONObjectWithData(msgJson!, options: .MutableContainers) as! [String:AnyObject] {
                    if let messObjs = json["mess"] as? [AnyObject] {
                        for case let messObj in (messObjs as? [[String:AnyObject]])! {
                            if let msg = MsgInfo(json: messObj) {
                                msgData.AddNewMsg(msg.from, newMsg: msg)
                                msgData.m_rawData.append(MsgInfoCoder(info: msg))
                            }
                        }
                        msgData.saveMsgToCache()
                        msgData.UpdateDelegates()
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

func httpGetMsgsPhotos(cIDs:Array<UInt64>) {
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cids":http.getUInt64ArrayParam(cIDs)]
    http.postRequest("photos", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let photosData = processErrorCode(response as! NSData, failed: nil)
            if photosData != nil {
                let subDatas = splitData(photosData!)
                for (i, cID) in cIDs.enumerate() {
                    contactsData.setPhoto(cID, data: subDatas[i], update: true)
                }
                msgData.UpdateDelegates()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

