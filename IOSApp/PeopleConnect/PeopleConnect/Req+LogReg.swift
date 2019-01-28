//
//  Requests+User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking
import UIKit

func httpVerifyCode(code:Int, cell:String) {
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: code)]
    
    http.postRequest("verify", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpRegistry(name:String, code:Int, cell:String, vcode:String, pass:String, photo:NSData, passed:(()->Void)?, failed:((String?)->Void)?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "name":name,
        "cell":cell,
        "code":NSNumber(integer: code),
        "vcode":vcode,
        "pass":pass,
        "device":deviceID]

    http.postDataRequest("registry", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFileData(photo, name:"1", fileName:"1", mimeType: "image/jpeg")
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if let regData = processErrorCode(response as! NSData, failed: failed) {
                if let json = getJson(regData) {
                    userInfo.userID = (UInt64)((json["user"]?.unsignedLongLongValue)!)
                    userInfo.userName = name
                    userInfo.countryCode = code
                    userInfo.cellNumber = cell
                    userInfo.password = pass
                    contactsData.addUser(userInfo.userID, name: userInfo.userName, flag: 0)
                    setContactPhoto(userInfo.userID, photo: photo)
                    userData.setCurUser()
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}

func httpLogon(code:Int, cell:String, pass:String, vcode:String, passed:(()->Void)?, failed:((String?)->Void)?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: code),
        "pass":pass,
        "vcode":vcode,
        "device":deviceID]

    http.postRequest("login", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if let logData = processErrorCode(response as! NSData, failed: failed) {
                if let json = getJson(logData) {
                    userInfo.userID = (UInt64)((json["user"]?.unsignedLongLongValue)!)
                    userInfo.userName = json["name"] as! String
                    userInfo.countryCode = code
                    userInfo.cellNumber = cell
                    userInfo.password = pass
                    contactsData.addUser(userInfo.userID, name: userInfo.userName, flag: 0)
                    userData.setCurUser()
                    
                    if let tagObjs = json["tags"] as? [AnyObject] {
                        for case let tagObj in (tagObjs as? [[String:AnyObject]])! {
                            if let tag = TagInfo(json: tagObj) {
                                let newTag = Tag(id: tag.tagID, father: tag.fatherID, name: tag.tagName)
                                contactsData.addSubTag(newTag)
                            }
                        }
                    }
                    
                    if let groupObjs = json["groups"] as? [AnyObject] {
                        for case let groupObj in (groupObjs as? [[String:AnyObject]])! {
                            if let group = GroupInfo(json: groupObj) {
                                addGroup(group)
                            }
                        }
                    }
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}
