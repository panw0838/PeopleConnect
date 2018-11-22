//
//  LoginView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class LoginView: UIViewController, LogonRequestCallback {
    
    func LogonUpdateUI() {
        self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logonCallbacks.append(self)
    }

    @IBAction func registry(sender: AnyObject) {
        var cell = 123456

        let cellNumber:String = String(cell)
        let password: String = "123456"
        httpRegistry(cellNumber, password: password)
        
        cell++
    }
    
    @IBAction func login1(sender: AnyObject) {
        httpLogon("123456", password: "123456")
    }
    
    @IBAction func login2(sender: AnyObject) {
        httpLogon("123457", password: "123456")

    }
    
    @IBAction func login3(sender: AnyObject) {
        httpLogon("123458", password: "123456")
    }
}
