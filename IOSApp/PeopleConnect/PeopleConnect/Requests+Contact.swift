//
//  Requests+Contact.swift
//  PeopleConnect
//
//  Created by apple on 18/11/20.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpGetContacts() {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
    http.postRequest("contacts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as! [String:AnyObject] {
                    var contacts:Array<ContactInfo> = Array<ContactInfo>()
                    var userTags:Array<TagInfo> = Array<TagInfo>()
                    
                    if let tagObjs = json["tags"] as? [AnyObject] {
                        for case let tagObj in (tagObjs as? [[String:AnyObject]])! {
                            if let tag = TagInfo(json: tagObj) {
                                userTags.append(tag)
                            }
                        }
                    }
                    
                    if let contactObjs = json["contacts"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contacts.append(contact)
                            }
                        }
                    }
                    httpSyncMessege()
                    contactsData.loadContacts(contacts, userTags: userTags)
                    for callback in contactCallbacks {
                        callback.ContactUpdateUI()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpRequestContact(contact:UInt64, flag:UInt64, name:String, messege:String) {
    let params: Dictionary = ["from":NSNumber(unsignedLongLong: userInfo.userID), "to":NSNumber(unsignedLongLong: contact), "name":name, "flag":NSNumber(unsignedLongLong: flag), "mess":messege]
    http.postRequest("requestcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
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
                for callback in contactCallbacks {
                    callback.ContactUpdateUI()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpRemContact(contact:UInt64) {
    let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "contact":NSNumber(unsignedLongLong: contact)]
    http.postRequest("remcontact", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                contactsData.remContact(contact)
                for callback in contactCallbacks {
                    callback.ContactUpdateUI()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpMoveContacts(tagID:UInt8, addMembers:Array<UInt64>, remMembers:Array<UInt64>) {
    let adds:NSMutableArray = http.getIDArrayParam(addMembers)
    let rems:NSMutableArray = http.getIDArrayParam(remMembers)
    let params:Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "tag":NSNumber(unsignedChar: tagID), "add":adds, "rem":rems]
    http.postRequest("updatetagmember", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                for member in addMembers {
                    contactsData.moveContactInTag(member, tagID: tagID)
                }
                for member in remMembers {
                    contactsData.moveContactOutTag(member, tagID: tagID)
                }
                for callback in contactCallbacks {
                    callback.ContactUpdateUI()
                }
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

