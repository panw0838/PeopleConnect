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

func httpRegistry(code:Int, cell:String, pass:String, photo:NSData, passed:(()->Void)?, failed:((String?)->Void)?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: code),
        "pass":pass,
        "device":deviceID]

    http.postDataRequest("registry", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFileData(photo, name:"1", fileName:"1", mimeType: "image/jpeg")
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let regData = processErrorCode(response as! NSData, failed: failed)
            if regData != nil {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(regData!, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    userInfo.userID = (UInt64)((dict["user"]?.unsignedLongLongValue)!)
                    userInfo.userName = dict["name"] as! String
                    let newContact = ContactInfo(id: userInfo.userID, f: 0, n: userInfo.userName)
                    contactsData.setPhoto(newContact.user, data: photo, update: true)
                    contactsData.m_contacts[newContact.user] = newContact
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}

func httpLogon(code:Int, cell:String, pass:String, passed:(()->Void)?, failed:((String?)->Void)?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: code),
        "pass":pass,
        "device":deviceID]

    http.postRequest("login", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let logData = processErrorCode(response as! NSData, failed: failed)
            if logData != nil {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(logData!, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    userInfo.userID = (UInt64)((dict["user"]?.unsignedLongLongValue)!)
                    userInfo.userName = dict["name"] as! String
                    let newContact = ContactInfo(id: userInfo.userID, f: 0, n: userInfo.userName)
                    contactsData.m_contacts[newContact.user] = newContact
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        }
    )
}
