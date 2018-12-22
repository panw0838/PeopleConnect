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

func httpRegistry(countryCode:Int, cellNumber:String, password:String, photo:NSData) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cellNumber,
        "code":NSNumber(integer: countryCode),
        "pass":password,
        "device":deviceID]

    http.postDataRequest("registry", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFileData(photo, name:"", fileName:"", mimeType: "image/jpeg")
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    userInfo.userID = (UInt64)((dict["user"]?.integerValue)!)
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpLogon(countryCode:Int, cellNumber:String, password:String) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = ["cell":cellNumber, "code":NSNumber(integer: countryCode), "pass":password, "device":deviceID]

    http.postRequest("login", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
            if (html.hasPrefix("Error")) {
                print("%s", html)
            }
            else {
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    userInfo.userID = (UInt64)((dict.valueForKey("user")?.integerValue)!)
                    userInfo.userName = dict["name"] as! String
                    let newContact = ContactInfo(id: userInfo.userID, f: 0, n: userInfo.userName)
                    contactsData.m_contacts[newContact.user] = newContact
                }
                httpGetContacts()
                httpSyncRequests()
                
                tcp.start("192.168.0.104", port: 8888)
                tcp.logon()
                
                for callback in logonCallbacks {
                    callback.LogonUpdateUI()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpIPChange() {
    
}