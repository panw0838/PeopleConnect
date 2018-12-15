//
//  LoginView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

var countryDict:Dictionary<Int, CountryInfo>? = nil

class LogView: UITableViewController {
    @IBOutlet weak var m_countryBtn: UIButton!
    @IBOutlet weak var m_cellInput: UITextField!
    @IBOutlet weak var m_passInput: UITextField!
    @IBOutlet weak var m_getCodeBtn: UIButton!
    @IBOutlet weak var m_logSwitchBtn: UIButton!
    @IBOutlet weak var m_logBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_countryBtn.setTitle(userData.getCountryCode(), forState: .Normal)
    }
    
    func countryCodeChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = input.characters.count
        
        okAction.enabled = false
        if nameSize > 0 && nameSize < 5 {
            let code = Int(input)
            if countryDict![code!] != nil {
                alert.message = "+" + input + " " + countryDict![code!]!.cnName
                okAction.enabled = true
            }
            else {
                alert.message = " "
            }
        }
    }
    
    @IBAction func changeCountryCode(sender: AnyObject) {
        countryDict = loadCountryInfo()
        let alert = UIAlertController(title: "请输入国家码", message: " ", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                self.m_countryBtn.setTitle("+" + (alert.textFields?.first?.text)!, forState: .Normal)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "不含+"
            textField.keyboardType = .NumberPad
            textField.addTarget(self, action: Selector("countryCodeChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    

}

class RegView: UITableViewController {
    @IBOutlet weak var m_nickNameInput: UITextField!
    @IBOutlet weak var m_countryBtn: UIButton!
    @IBOutlet weak var m_cellInput: UITextField!
    @IBOutlet weak var m_passInput: UITextField!
    @IBOutlet weak var m_regBtn: UIButton!
    
    func countryCodeChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let input:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = input.characters.count
        
        okAction.enabled = false
        if nameSize > 0 && nameSize < 5 {
            let code = Int(input)
            if countryDict![code!] != nil {
                alert.message = "+" + input + " " + countryDict![code!]!.cnName
                okAction.enabled = true
            }
            else {
                alert.message = " "
            }
        }
    }
    
    @IBAction func changeCountryCode(sender: AnyObject) {
        countryDict = loadCountryInfo()
        let alert = UIAlertController(title: "请输入国家码", message: " ", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                self.m_countryBtn.setTitle("+" + (alert.textFields?.first?.text)!, forState: .Normal)
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "不含+"
            textField.keyboardType = .NumberPad
            textField.addTarget(self, action: Selector("countryCodeChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        m_countryBtn.setTitle(userData.getCountryCode(), forState: .Normal)
    }
}

class LoginView: UIViewController, LogonRequestCallback {
    
    
    @IBOutlet weak var m_logRegSwitch: UISegmentedControl!
    @IBOutlet weak var m_logView: UIView!
    @IBOutlet weak var m_regView: UIView!
    
    @IBAction func switchLogReg(sender: AnyObject) {
        if m_logRegSwitch.selectedSegmentIndex == 0 {
            m_logView.hidden = false
            m_regView.hidden = true
        }
        else {
            m_logView.hidden = true
            m_regView.hidden = false
        }
    }
    
    func LogonUpdateUI() {
        self.performSegueWithIdentifier("ShowMainMenu", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logonCallbacks.append(self)
        m_logView.hidden = false
        m_regView.hidden = true
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
