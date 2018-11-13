//
//  LoginView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class LoginView: UIViewController {

    @IBAction func registry(sender: AnyObject) {
        let cellNumber:String = "86000001"
        let password: String = "123456"
        let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
        let params: Dictionary = ["cell":cellNumber, "code":"0838", "pass":password, "device":deviceID]
        
        http.postRequest("registry", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Success")) {
                    self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
                    print("%s", html)
                }
                else {
                    print("%s", html)
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
    
    @IBAction func login(sender: AnyObject) {
        let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
        let params: Dictionary = ["cell":"86000001", "code":"0838", "pass":"123456", "device":deviceID]
        
        http.postRequest("login", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Success")) {
                    self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
                    print("%s", html)
                }
                else {
                    print("%s", html)
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            })
    }
    
    func logSuccess(task: NSURLSessionDataTask, response: AnyObject) {
        let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
        if (html.hasPrefix("Success")) {
            self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
            print("%s", html)
        }
        else {
            print("%s", html)
        }
    }
    
    func logFail(task: NSURLSessionDataTask?, error : NSError) {
        print("%s", error.debugDescription)
    }
}
