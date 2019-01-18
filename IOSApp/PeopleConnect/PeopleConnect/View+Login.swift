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
    @IBOutlet weak var m_passLabel: UILabel!
    @IBOutlet weak var m_photo: UIImageView!
    
    @IBOutlet weak var m_logBtn: UIButton!
    
    var m_usePassword = true
    var m_enableColor:UIColor? = nil
    var m_father:LoginView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        m_cellBtn.layer.cornerRadius = 10
        m_countryBtn.layer.cornerRadius = 10
        m_passBtn.layer.cornerRadius = 10
        m_photo.layer.cornerRadius = 10
        m_photo.layer.masksToBounds = true
        m_countryBtn.setTitle(getCountryCodeString(), forState: .Normal)
        m_getCodeBtn.hidden = true
        m_logBtn.enabled = false
        m_enableColor = m_logBtn.backgroundColor
        m_logBtn.backgroundColor = UIColor.grayColor()
        
        if userData.getCurUser() {
            let photo = getContactPhoto(userInfo.userID)
            if photo != nil {
                m_photo.image = UIImage(data: photo!)
            }
            m_countryCode = userInfo.countryCode
            m_countryBtn.setTitle("+"+String(m_countryCode), forState: .Normal)
            m_cellNumber = userInfo.cellNumber
            m_cellBtn.setTitle(m_cellNumber, forState: .Normal)
        }
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
            m_passLabel.text = "验证码"
        }
        else {
            m_passBtn.setTitle("请输入验证码", forState: .Normal)
            m_getCodeBtn.hidden = false
            m_logSwitchBtn.setTitle("密码登陆", forState: .Normal)
            m_passLabel.text = "密码"
        }
    }

    func logFail(msg:String?) {
        // show error
        gLoadingView.stopLoading()
        m_father?.showError(msg)
    }
    
    func logSuccess() {
        tcp.start("192.168.0.104", port: 8888)
        tcp.logon()
        gLoadingView.stopLoading()
        MsgData.shared.loadMsgFromDB()
        MsgData.shared.Update()
        m_father?.performSegueWithIdentifier("ShowMainMenu", sender: nil)
    }

    @IBAction func log() {
        httpLogon(m_countryCode, cell: m_cellNumber, pass: m_password, passed: logSuccess, failed: logFail)
        gLoadingView.startLoading()
    }
    
    override func updateNextButton() {
        m_logBtn.enabled = m_cellNumber.characters.count != 0 && m_password.characters.count != 0
        m_logBtn.backgroundColor = m_logBtn.enabled ? m_enableColor : UIColor.grayColor()
    }
}

class RegView: BaseLogRegView, PhotoClipperDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var m_nickNameBtn: UIButton!
    @IBOutlet weak var m_regBtn: UIButton!
    @IBOutlet weak var m_photoBtn: UIButton!
    
    var m_photo:NSData? = nil
    var m_nickName:String = ""
    var m_picker = ImgPicker(maxCount: 1)
    var m_enableColor:UIColor? = nil
    var m_father:LoginView? = nil
    
    @IBAction func reg(sender: AnyObject) {
        httpRegistry(m_nickName, code: m_countryCode, cell: m_cellNumber, pass: m_password, photo: m_photo!,
            passed: { ()->Void in
                gLoadingView.stopLoading()
                self.m_father!.performSegueWithIdentifier("ShowMainMenu", sender: nil)
            },
            failed: { (errMsg:String?)->Void in
                gLoadingView.stopLoading()
                self.m_father?.showError(errMsg)
            }
        )
        gLoadingView.startLoading()
    }
    
    @IBAction func pickPhoto() {
        let navi = UINavigationController(rootViewController: m_picker)
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
                self.m_passBtn.setTitle(self.m_password, forState: .Normal)
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
                self.m_nickName = (alert.textFields?.first?.text)!
                self.m_nickNameBtn.setTitle(self.m_nickName, forState: .Normal)
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
        m_photoBtn.layer.cornerRadius = 10
        m_photoBtn.layer.masksToBounds = true
        m_countryBtn.setTitle(getCountryCodeString(), forState: .Normal)
        m_regBtn.enabled = false
        m_picker.m_cliperDelegate = self
        m_enableColor = m_regBtn.backgroundColor
        m_regBtn.backgroundColor = UIColor.grayColor()
    }
    
    func didClippedPickImage(img: UIImage) {
        self.m_photoBtn.setImage(img, forState: .Normal)
        self.m_photo = UIImagePNGRepresentation(img)
        m_picker.dismissViewControllerAnimated(true, completion: nil)
        updateNextButton()
    }

    override func updateNextButton() {
        m_regBtn.enabled =
            m_cellNumber.characters.count != 0 &&
            m_password.characters.count != 0 &&
            m_nickName.characters.count != 0 &&
            m_photo != nil
        m_regBtn.backgroundColor = m_regBtn.enabled ? m_enableColor : UIColor.grayColor()
    }
}

class LoginView: UIViewController {

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
    
    func showError(errMsg:String?) {
        let err = errMsg == nil ? "未知错误" : errMsg
        let alert = UIAlertController(title: err, message: "", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "确定", style: .Default, handler: nil)
        
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_logView.hidden = false
        m_regView.hidden = true
        
        for child in self.childViewControllers {
            let logView = child as? LogView
            if logView != nil {
                logView?.m_father = self
            }
            let regView = child as? RegView
            if regView != nil {
                regView?.m_father = self
            }
        }
    }

    func logSuccess() {
        tcp.start("192.168.0.104", port: 8888)
        tcp.logon()
        gLoadingView.stopLoading()
        MsgData.shared.loadMsgFromDB()
        MsgData.shared.Update()
        performSegueWithIdentifier("ShowMainMenu", sender: nil)
    }
    
    @IBAction func login1(sender: AnyObject) {
        gLoadingView.startLoading()
        httpLogon(86, cell: "13700000000", pass: "qqqqqqqq", passed: logSuccess, failed: nil)
    }
    
    @IBAction func login2(sender: AnyObject) {
        httpLogon(86, cell: "13700000002", pass: "qqqqqqqq", passed: logSuccess, failed: nil)
    }
    
    @IBAction func login3(sender: AnyObject) {
        httpLogon(86, cell: "13700000003", pass: "qqqqqqqq", passed: logSuccess, failed: nil)
    }
}
