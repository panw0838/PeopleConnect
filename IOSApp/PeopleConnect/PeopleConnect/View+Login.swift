//
//  LoginView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import PhotosUI

var countryDict:Dictionary<Int, CountryInfo>? = nil

class BaseLogRegView: UITableViewController {
    @IBOutlet weak var m_countryBtn: UIButton!
    @IBOutlet weak var m_cellBtn: UIButton!
    @IBOutlet weak var m_passBtn: UIButton!

    var m_countryCode:Int = 86
    var m_cellNumber:String = ""
    var m_password:String = ""

    func countryCodeChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let input:String = (sender.text)!
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
    
    func cellNumberChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        let input:String = (sender.text)!
        let inputSize = input.characters.count
        
        okAction.enabled = false
        
        switch m_countryCode {
        case 86:
            if inputSize == 11 {
                okAction.enabled = checkCNCellNumber(input)
            }
            break
        case 1:
            okAction.enabled = (inputSize == 10)
            break
        default:
            break
        }
    }
    
    @IBAction func changeCellNumber(sender:AnyObject) {
        let alert = UIAlertController(title: "请输入手机号", message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                let cellNumber = (alert.textFields?.first?.text)!
                self.m_cellBtn.setTitle(cellNumber, forState: .Normal)
                self.m_cellNumber = cellNumber
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = ""
            textField.keyboardType = .NumberPad
            textField.addTarget(self, action: Selector("cellNumberChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateNextButton() {
    }
}

class LogView: BaseLogRegView {
    @IBOutlet weak var m_logSwitchBtn: UIButton!
    @IBOutlet weak var m_getCodeBtn: UIButton!
    
    @IBOutlet weak var m_logBtn: UIButton!
    
    var m_usePassword = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_cellBtn.layer.cornerRadius = 10
        m_countryBtn.layer.cornerRadius = 10
        m_passBtn.layer.cornerRadius = 10
        m_countryBtn.setTitle(getCountryCode(), forState: .Normal)
        m_getCodeBtn.hidden = true
        m_logBtn.enabled = false
    }
    
    func passwordChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        let input:String = (sender.text)!
        let inputSize = input.characters.count
        
        if m_usePassword {
            okAction.enabled = (inputSize >= 8 && inputSize <= 16)
        }
        else {
            okAction.enabled = (inputSize == 4)
        }
    }
    
    @IBAction func inputPassword(sender:AnyObject) {
        let title = m_usePassword ? "请输入密码" : "请输入验证码"
        let alert = UIAlertController(title: title, message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                let input = (alert.textFields?.first?.text)!
                self.m_password = input
                self.m_passBtn.setTitle((self.m_usePassword ? "********" : input), forState: .Normal)
                self.updateNextButton()
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "请输入" + (self.m_usePassword ? "8到16位密码" : "4位验证码")
            textField.keyboardType = (self.m_usePassword ? .ASCIICapable : .NumberPad)
            textField.addTarget(self, action: Selector("passwordChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeLogMethod(sender: AnyObject) {
        m_usePassword = !m_usePassword
        if m_usePassword {
            m_passBtn.setTitle("请输入密码", forState: .Normal)
            m_getCodeBtn.hidden = true
            m_logSwitchBtn.setTitle("验证码登陆", forState: .Normal)
        }
        else {
            m_passBtn.setTitle("请输入验证码", forState: .Normal)
            m_getCodeBtn.hidden = false
            m_logSwitchBtn.setTitle("密码登陆", forState: .Normal)
        }
    }
    
    @IBAction func log() {
        httpLogon(m_countryCode, cellNumber: m_cellNumber, password: m_password)
    }
    
    override func updateNextButton() {
        m_logBtn.enabled = m_cellNumber.characters.count != 0 && m_password.characters.count != 0
    }
}

class RegView: BaseLogRegView, ImgPickerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var m_nickNameBtn: UIButton!
    @IBOutlet weak var m_regBtn: UIButton!
    @IBOutlet weak var m_photoBtn: UIButton!
    
    var m_photo:NSData? = nil
    var m_nickName:String = ""
    var m_picker:ImgPicker? = nil
    
    @IBAction func pickPhoto() {
        //self.performSegueWithIdentifier("PickPhoto", sender: nil)
        //self.presentViewController(m_picker!, animated: true, completion: nil)
        
        let navi = UINavigationController(rootViewController: m_picker!)
        navi.delegate = self
        self.presentViewController(navi, animated: true, completion: nil)
    }
    
    func passwordChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        let input:String = (sender.text)!
        let inputSize = input.characters.count
        
        okAction.enabled = (inputSize >= 8 && inputSize <= 16)
    }

    @IBAction func inputPassword(sender:AnyObject) {
        let alert = UIAlertController(title: "请输入密码", message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                self.m_password = (alert.textFields?.first?.text)!
                self.m_passBtn.setTitle("********", forState: .Normal)
                self.updateNextButton()
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "请输入8到16位密码"
            textField.keyboardType = .ASCIICapable
            textField.addTarget(self, action: Selector("passwordChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func nickNameChanged(sender:UITextField) {
        let alert = self.presentedViewController as! UIAlertController
        let okAction:UIAlertAction = alert.actions.last!
        let input:String = (sender.text)!
        let inputSize = input.characters.count
        
        okAction.enabled = (inputSize > 0 && inputSize <= 18)
    }
    
    @IBAction func inputNickName(sender:AnyObject) {
        let alert = UIAlertController(title: "请输入昵称", message: "", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                let nickName = (alert.textFields?.first?.text)!
                self.m_nickNameBtn.setTitle(nickName, forState: .Normal)
                self.updateNextButton()
        })
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "昵称不超过18个字符"
            textField.keyboardType = .Default
            textField.addTarget(self, action: Selector("nickNameChanged:"), forControlEvents: .EditingChanged)
        }
        okAction.enabled = false
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        m_nickNameBtn.layer.cornerRadius = 10
        m_countryBtn.layer.cornerRadius = 10
        m_cellBtn.layer.cornerRadius = 10
        m_passBtn.layer.cornerRadius = 10
        m_countryBtn.setTitle(getCountryCode(), forState: .Normal)
        m_regBtn.enabled = false
        m_picker = ImgPicker()
        m_picker?.m_delegate = self
    }
    
    func didFinishedPickImage(imgs: Array<PHAsset>) {
        let asset = imgs[0]
        
        PHCachingImageManager().requestImageForAsset(asset, targetSize: CGSizeMake(80, 80), contentMode: .AspectFill, options: nil, resultHandler: {(result:UIImage?, _: [NSObject:AnyObject]?)->Void in
            self.m_photoBtn.setImage(result!, forState: .Normal)
            self.m_photo = UIImagePNGRepresentation(result!)
            })
        
        m_picker!.dismissViewControllerAnimated(true, completion: nil)
    }

    override func updateNextButton() {
        m_regBtn.enabled =
            m_cellNumber.characters.count != 0 &&
            m_password.characters.count != 0 &&
            m_nickName.characters.count != 0 &&
            m_photo != nil
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
        httpLogon(0, cellNumber: "123456", password: "123456")
    }
    
    @IBAction func login2(sender: AnyObject) {
        httpLogon(0, cellNumber: "123457", password: "123456")

    }
    
    @IBAction func login3(sender: AnyObject) {
        httpLogon(0, cellNumber: "123458", password: "123456")
    }
}
