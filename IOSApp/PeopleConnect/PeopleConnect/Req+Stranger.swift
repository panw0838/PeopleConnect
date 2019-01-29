//
//  Req+Stranger.swift
//  PeopleConnect
//
//  Created by apple on 19/1/7.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

func httpGetNearbyUsers(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    contactsData.m_nearUsers.clearContacts()
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "x":NSNumber(double: userInfo.x),
        "y":NSNumber(double: userInfo.y)]
    http.postRequest("nearusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: failed)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_nearUsers.addMember(contact)
                                contactsData.addUser(contact)
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_nearUsers)
                        contactsData.getUsers(
                            { () -> Void in
                                contactsData.updateDelegates()
                            },
                            failed: nil)
                    }
                    contactsData.updateDelegates()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpRegFaceUsers(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    contactsData.m_faceUsers.clearContacts()
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "x":NSNumber(double: userInfo.x),
        "y":NSNumber(double: userInfo.y)]
    http.postRequest("regfaceusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                passed?()
            }
            else {
                failed?(err: "请求失败")
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpGetFaceUsers(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    let params: Dictionary = ["uid":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("getfaceusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: failed)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_faceUsers.addMember(contact)
                                contactsData.addUser(contact)
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_faceUsers)
                        contactsData.getUsers(
                            { () -> Void in
                                contactsData.updateDelegates()
                            },
                            failed: nil)
                    }
                    contactsData.updateDelegates()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpDidFaceUsers() {
    let params: Dictionary = ["uid":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("remfaceusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpGetCellContacts(names:Array<String>, cells:Array<String>, passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    contactsData.m_cellUsers.clearContacts()
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "code":NSNumber(integer: userInfo.countryCode),
        "names":http.getStringArrayParam(names),
        "cells":http.getStringArrayParam(cells)]
    http.postRequest("searchusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: failed)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_cellUsers.addMember(contact)
                                contactsData.addUser(contact)
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_cellUsers)
                        contactsData.getUsers(
                            { () -> Void in
                                contactsData.updateDelegates()
                            },
                            failed: nil)
                    }
                    contactsData.updateDelegates()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
    })
}

func httpGetSuggestContacts(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    contactsData.m_rcmtUsers.clearContacts()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("possiblecontacts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: failed)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let usersObjs = json["users"] as? [AnyObject] {
                        for case let userObj in (usersObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: userObj) {
                                contactsData.m_rcmtUsers.addMember(contact)
                                contactsData.addUser(contact)
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_rcmtUsers)
                        contactsData.getUsers(
                            { () -> Void in
                                contactsData.updateDelegates()
                            },
                            failed: nil)
                    }
                    contactsData.updateDelegates()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpGetBothLikeUsers(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    contactsData.m_likeUsers.clearContacts()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("getbothlikeusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: failed)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let usersObjs = json["users"] as? [AnyObject] {
                        for case let userObj in (usersObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: userObj) {
                                contactsData.m_likeUsers.addMember(contact)
                                contactsData.addUser(contact)
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_likeUsers)
                        contactsData.getUsers(
                            { () -> Void in
                                contactsData.updateDelegates()
                            },
                            failed: nil)
                    }
                    contactsData.updateDelegates()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}
