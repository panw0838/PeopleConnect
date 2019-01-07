//
//  Req+Stranger.swift
//  PeopleConnect
//
//  Created by apple on 19/1/7.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

func httpGetNearbyUsers() {
    contactsData.m_nearUsers.clearContacts()
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "x":NSNumber(double: userInfo.x),
        "y":NSNumber(double: userInfo.y)]
    http.postRequest("nearusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_nearUsers.addMember(contact)
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_nearUsers)
                        contactsData.getPhotos(contactsData.m_nearUsers.m_members)
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
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

func httpGetFaceUsers() {
    let params: Dictionary = ["uid":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("getfaceusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_faceUsers.addMember(contact)
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_faceUsers)
                        contactsData.getPhotos(contactsData.m_faceUsers.m_members)
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
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

func httpGetCellContacts(names:Array<String>, cells:Array<String>) {
    contactsData.m_cellUsers.clearContacts()
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "code":NSNumber(integer: getCountryCode()),
        "names":http.getStringArrayParam(names),
        "cells":http.getStringArrayParam(cells)]
    http.postRequest("searchusers", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_cellUsers.addMember(contact)
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        contactsData.updateStrangerTags(contactsData.m_cellUsers)
                        contactsData.getPhotos(contactsData.m_cellUsers.m_members)
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpGetSuggestContacts() {
    contactsData.m_rcmtUsers.clearContacts()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("possiblecontacts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
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
                        contactsData.getPhotos(contactsData.m_rcmtUsers.m_members)
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}
