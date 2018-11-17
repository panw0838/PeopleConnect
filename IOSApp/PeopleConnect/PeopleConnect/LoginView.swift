//
//  LoginView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class LoginView: UIViewController {
    
    var cell = 123456

    @IBAction func registry(sender: AnyObject) {
        let cellNumber:String = String(cell)
        let password: String = "123456"
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
                    //self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
        cell++
    }
    
    @IBAction func login(sender: AnyObject) {
        let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
        let params: Dictionary = ["cell":String(123456), "code":"0838", "pass":"123456", "device":deviceID]
        
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
                    self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            })
    }
}
