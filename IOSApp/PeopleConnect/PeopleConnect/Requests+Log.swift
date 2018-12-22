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

protocol LogDelegate {
    func logSuccess()->Void
    func logFail(msg:String?)->Void
}

func httpRegistry(countryCode:Int, cell:String, pass:String, photo:NSData, delegate:LogDelegate?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: countryCode),
        "pass":pass,
        "device":deviceID]

    http.postDataRequest("registry", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFileData(photo, name:"1", fileName:"1", mimeType: "image/jpeg")
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let data = response as! NSData
            var errCode:UInt8 = 0
            data.getBytes(&errCode, length: sizeof(UInt8))
            if errCode == 0 {
                let regData = data.subdataWithRange(NSRange(location: 1, length: data.length-1))
                let jsonObj = try? NSJSONSerialization.JSONObjectWithData(regData, options: .MutableContainers)
                if (jsonObj != nil) {
                    let dict: NSDictionary = jsonObj as! NSDictionary
                    userInfo.userID = (UInt64)((dict["user"]?.unsignedLongLongValue)!)
                }
                delegate?.logSuccess()
            }
            else {
                let errMsgs:Dictionary = [
                    1:"服务器错误",
                    2:"国家码错误",
                    3:"手机号错误",
                    4:"密码错误",
                    5:"头像错误"]
                let errMsg = errMsgs[Int(errCode)]
                delegate?.logFail(errMsg)
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            delegate?.logFail("请求失败")
        }
    )
}

func httpLogon(countryCode:Int, cell:String, pass:String, delegate:LogDelegate?) {
    let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
    let params: Dictionary = [
        "cell":cell,
        "code":NSNumber(integer: countryCode),
        "pass":pass,
        "device":deviceID]

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

            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
    })
}
