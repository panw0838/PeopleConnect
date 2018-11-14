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
                        let newTag: TagInfo = TagInfo(id: tagID, father: 0, name: name)
                        let newTab: UITabBarItem = UITabBarItem.init(title: name, image: nil, tag: userTags.count)
                        userTags.append(newTag)
                        contactsData.addTag(Tag(id: tagID, father: 0, name: name))
                        self.m_tabsBar.items?.append(newTab)
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
                    var idx = 0
                    for t in userTags {
                        if t.tagID == tag {
                            userTags.removeAtIndex(idx)
                            break
                        }
                        idx++
                    }
                    contactsData.loadContacts()
                    self.updateTags()
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
                    print("%s", html)
                }
                else {
                    let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                    if (jsonObj != nil) {
                        let dict: NSDictionary = jsonObj as! NSDictionary
                        let uid: UInt64 = (UInt64)((dict["user"]?.integerValue)!)
                        let name: String = dict["name"] as! String
                        print("%x %s", uid, name)
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
                    contacts.append(ContactInfo(id: contact, f: flag, n: name))
                    contactsData.loadContacts()
                    self.m_contacts.reloadData()
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
    
    func httpRemContact(contact:UInt64) {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID), "contact":NSNumber(unsignedLongLong: contact)]
        http.postRequest("addcontact", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    var idx = 0
                    for con in contacts {
                        if con.user == contact {
                            contacts.removeAtIndex(idx)
                            break
                        }
                        idx++
                    }
                    contactsData.loadContacts()
                    self.m_contacts.reloadData()
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
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
                        contacts.removeAll()
                        userTags.removeAll()
                        
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
                        contactsData.loadContacts()
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
