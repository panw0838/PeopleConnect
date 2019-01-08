//
//  TagRequests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/20.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func httpAddTag(father:UInt8, name:String) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "father":NSNumber(unsignedChar: father),
        "name":name]
    http.postRequest("addtag", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let tagData = processErrorCode(response as! NSData, failed: nil)
            if tagData != nil {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(tagData!, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    let tagID: UInt8 = UInt8((dict["tag"]?.integerValue)!)
                    contactsData.addSubTag(Tag(id: tagID, father: father, name: name))
                    contactsData.updateDelegates()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpRemTag(tag:Tag) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "tag":NSNumber(unsignedChar: tag.m_tagID)]
    http.postRequest("remtag", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if getErrorCode(response as! NSData) == 0 {
                tag.m_father?.remSubTag(tag)
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
