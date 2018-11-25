//
//  Requests+User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

func httpRegistry(cellNumber:String, password:String) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = ["cell":cellNumber, "code":"0838", "pass":password, "device":deviceID]

    http.postRequest("registry", params: params,
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
                for callback in contactCallbacks {
                    //callback.ContactUpdateUI()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}

func httpLogon(cellNumber:String, password:String) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = ["cell":cellNumber, "code":"0838", "pass":password, "device":deviceID]

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
                }
                httpGetContacts()
                httpSyncRequests()
                
                tcp.start("192.168.0.103", port: 8888)
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