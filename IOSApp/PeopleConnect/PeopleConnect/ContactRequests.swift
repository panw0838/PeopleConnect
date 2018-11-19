//
//  ContactRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/14.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

extension ContactsView {
    func httpAddTag(father:UInt8, name:String) {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "father":NSNumber(unsignedChar: father), "name":name]
        http.postRequest("addtag", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                    if (jsonObj != nil) {
                        let dict: NSDictionary = jsonObj as! NSDictionary
                        let tagID: UInt8 = (UInt8)((dict["tag"]?.integerValue)!)
                        contactsData.addTag(Tag(id: tagID, father: father, name: name))
                        self.updateTags()
                        self.m_curTag = contactsData.numMainTags() - 1
                        self.m_contacts.reloadData()
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
    
    func httpRemTag(tag:UInt8) {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "tag":NSNumber(unsignedChar: tag)]
        http.postRequest("remtag", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    contactsData.remTag(tag)
                    self.m_curTag = 0
                    self.updateTags()
                    self.m_contacts.reloadData()
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
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    let error = UIAlertController(title: "错误", message: html, preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
                    error.addAction(okAction)
                    //holding.presentingViewController!.dismissViewControllerAnimated(false, completion: nil)
                    self.presentViewController(error, animated: false, completion: nil)
                }
                else {
                    let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                    if (jsonObj != nil) {
                        let dict: NSDictionary = jsonObj as! NSDictionary
                        self.m_selectContact.user = (UInt64)((dict["user"]?.integerValue)!)
                        self.m_selectContact.name = dict["name"] as! String
                        self.m_selectContact.flag = 0
                        //self.dismissViewControllerAnimated(false, completion: nil)
                        self.performSegueWithIdentifier("ShowContact", sender: nil)
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                let error = UIAlertController(title: "错误", message: "请求失败", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
                error.addAction(okAction)
                self.presentViewController(error, animated: false, completion: nil)
            })
    }
    
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
                        contactsData.loadContacts(contacts, userTags: userTags)
                        self.updateTags()
                        self.m_contacts.reloadData()
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
}

extension ContactView {
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
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
}

extension MoveMemberView {
    func httpMoveMembers(tagID:UInt8, addMembers:Array<UInt64>, remMembers:Array<UInt64>) {
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
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
}
