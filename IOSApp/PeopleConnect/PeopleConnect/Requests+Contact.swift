//
//  Requests+Contact.swift
//  PeopleConnect
//
//  Created by apple on 18/11/20.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpGetFriends(passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("contacts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let conData = processErrorCode(response as! NSData, failed: failed)
            if conData != nil {
                if let json = getJson(conData!) {
                    var contacts:Array<ContactInfo> = Array<ContactInfo>()
                    
                    if let contactObjs = json["contacts"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contacts.append(contact)
                            }
                        }
                    }
                    
                    contactsData.loadContacts(contacts)
                    passed?()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpGetNearbyUsers() {
    contactsData.m_stranger.clearContacts()
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
                                contactsData.m_stranger.m_members.append(contact.user)
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        
                        let photoList = getPhotoMissingList(contactsData.m_stranger.m_members)
                        if photoList.count > 0 {
                            httpGetPhotos(photoList,
                                passed: {()->Void in
                                    contactsData.updateDelegates()
                                },
                                failed: nil)
                        }
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpGetPossibleContacts() {
    contactsData.m_possible.clearContacts()
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("possiblecontacts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let usersData = processErrorCode(response as! NSData, failed: nil)
            if usersData != nil {
                if let json = getJson(usersData!) {
                    if let usersObjs = json["users"] as? [AnyObject] {
                        for case let userObj in (usersObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: userObj) {
                                contactsData.m_possible.m_members.append(contact.user)
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        
                        let photoList = getPhotoMissingList(contactsData.m_possible.m_members)
                        if photoList.count > 0 {
                            httpGetPhotos(photoList,
                                passed: {()->Void in
                                    contactsData.updateDelegates()
                                },
                                failed: nil)
                        }
                    }
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpGetUsers(cIDs:Array<UInt64>, passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cids":http.getUInt64ArrayParam(cIDs)]
    http.postRequest("users", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let conData = processErrorCode(response as! NSData, failed: failed)
            if conData != nil {
                if let json = getJson(conData!) {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.addUser(contact)
                            }
                        }
                    }
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpGetPhotos(cIDs:Array<UInt64>, passed: (()->Void)?, failed: ((err:String?)->Void)?) {
    if cIDs.count == 0 {
        return
    }
    
    let contacts:NSMutableArray = http.getUInt64ArrayParam(cIDs)
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cids":contacts]
    http.postRequest("photos", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let photosData = processErrorCode(response as! NSData, failed: failed)
            if photosData != nil {
                let subDatas = splitData(photosData!)
                for (i, cID) in cIDs.enumerate() {
                    setContactPhoto(cID, photo: subDatas[i])
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?(err: "请求失败")
        }
    )
}

func httpAddContact(contact:UInt64, name:String) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "contact":NSNumber(unsignedLongLong: contact),
        "name":name]
    http.postRequest("addcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                contactsData.addContact(ContactInfo(id: contact, f: UndefineBit, n: name))
                contactsData.updateDelegates()

                msgData.remRequest(contact)
                msgData.UpdateRequestsDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpRemContact(contact:UInt64) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "contact":NSNumber(unsignedLongLong: contact)]
    http.postRequest("remcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                contactsData.remContact(contact)
                contactsData.updateDelegates()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpMoveContacts(tag:Tag, addMembers:Array<UInt64>, remMembers:Array<UInt64>) {
    let adds:NSMutableArray = http.getUInt64ArrayParam(addMembers)
    let rems:NSMutableArray = http.getUInt64ArrayParam(remMembers)
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "tag":NSNumber(unsignedChar: tag.m_tagID),
        "sys":NSNumber(bool: (tag.m_fatherID == 0)),
        "add":adds,
        "rem":rems]
    http.postRequest("updatetagmember", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                contactsData.moveContactsInTag(addMembers, tag: tag)
                contactsData.moveContactsOutTag(remMembers, tag: tag)
                contactsData.updateDelegates()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpSearchContact(key:String) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "key":key]
    http.postRequest("searchcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            var uid:UInt64 = 0
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
            }
            else {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    var contact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")
                    contact.user = (UInt64)((dict["user"]?.integerValue)!)
                    contact.name = dict["name"] as! String
                    contactsData.addContact(contact)
                    uid = contact.user
                }
            }
            for callback in searchCallbacks {
                callback.SearchUpdateUI(uid)
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

