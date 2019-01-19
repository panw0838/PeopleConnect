//
//  MessegeView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

enum MsgStatus {
    case Success
    case Fail
    case Sending
}

class MsgStatusView: UIView {
    var m_loading = UIActivityIndicatorView()
    var m_warning = UIImageView(frame: CGRectZero)
    
    var m_status:MsgStatus = .Success
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        m_loading.activityIndicatorViewStyle = .Gray
        addSubview(m_loading)
        addSubview(m_warning)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startLoading() {
        m_status = .Sending
        
        self.hidden = false
        m_loading.center = self.center
        m_loading.startAnimating()
        m_loading.hidden = false
        m_loading.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        m_warning.hidden = true
    }
    
    func stopLoading(success:Bool) {
        m_status = success ? .Success : .Fail
        
        m_loading.stopAnimating()
        if success {
            self.hidden = true
        }
        else {
            self.hidden = false
            
            m_loading.hidden = true
            
            m_warning.hidden = false
            m_warning.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
            m_warning.image = UIImage(named: "message_sent_fail")
        }
    }
    
    func reloadStatus(status:MsgStatus) {
        if status == .Success {
            if m_loading.isAnimating() {
                m_loading.stopAnimating()
            }
            m_loading.hidden = true
            m_warning.hidden = true
        }
        else if status == .Fail {
            if m_loading.isAnimating() {
                m_loading.stopAnimating()
            }
            m_loading.hidden = true
            m_warning.hidden = false
        }
        else {
            if !m_loading.isAnimating() {
                m_loading.startAnimating()
            }
            m_loading.hidden = false
            m_warning.hidden = true
        }
    }
}

let MsgTimeFont = UIFont.systemFontOfSize(13)

class MsgCell: UITableViewCell {
    var m_photo = UIButton(frame: CGRectZero)
    var m_message = UIButton(frame: CGRectZero)
    var m_status  = MsgStatusView(frame: CGRectZero)
    var m_time    = UILabel(frame: CGRectZero)
    
    var m_msg:MsgInfo?
    var m_index:Int = 0
    var m_father:ConversationView? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    func initSubviews() {
        m_photo.layer.cornerRadius = 10
        m_photo.layer.masksToBounds = true
        m_photo.addTarget(self, action: Selector("showContact"), forControlEvents: .TouchDown)
        addSubview(m_photo)

        m_time.textAlignment = .Center
        m_time.textColor = UIColor.grayColor()
        m_time.font = MsgTimeFont
        addSubview(m_time)

        addSubview(m_status)

        m_message.titleLabel?.font = msgFont
        m_message.titleLabel?.numberOfLines = 0
        m_message.titleLabel?.lineBreakMode = .ByWordWrapping
        m_message.contentEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
        addSubview(m_message)
    }
    
    func showContact() {
        m_father?.m_text.endEditing(true)
        ContactView.ContactID = m_msg!.from
        m_father?.performSegueWithIdentifier("ShowContact", sender: self)
    }
    
    func startLoading() {
        m_status.startLoading()
    }
    
    func stopLoading(success:Bool) {
        m_status.stopLoading(success)
    }
    
    func reload(msg:MsgFrame, sending:Bool, width:CGFloat) {
        let pad:CGFloat = 8
        let pSize:CGFloat = 40
        let textGap:CGFloat = 20
        let statusSize:CGFloat = 20
        let maxTextSize = CGSizeMake(width - pSize*2 - pad * 4, CGFloat(MAXFLOAT))
        let textSize = getMsgSize(msg.m_info.data, maxSize: maxTextSize, font: msgFont)
        let textBubSize = CGSizeMake(textSize.width + textGap*2, textSize.height + textGap*2)
        let timeHeight:CGFloat = 15
        
        m_msg = msg.m_info
        
        var buttom = pad
        
        if msg.m_showTime {
            m_time.hidden = false
            m_time.text = getTimeString(msg.m_info.time)
            m_time.frame = CGRectMake(0, buttom, width, timeHeight)
            buttom += timeHeight
        }
        else {
            m_time.hidden = true
        }
        
        m_photo.setImage(getPhoto(msg.m_info.from), forState: .Normal)
        m_message.setTitle(msg.m_info.data, forState: .Normal)
        
        m_photo.frame.size = CGSizeMake(pSize, pSize)
        m_message.frame.size = CGSizeMake(textBubSize.width, (textBubSize.height > pSize ? textBubSize.height : pSize))
        
        if msg.m_info.from == userInfo.userID {
            m_photo.frame.origin = CGPointMake(width - pad - pSize, buttom)
            m_message.frame.origin = CGPointMake(m_photo.frame.origin.x - textBubSize.width - pad, buttom)

            m_message.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_send_nor"), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_send_press"), forState: .Highlighted)
        }
        else {
            m_photo.frame.origin = CGPointMake(pad, buttom)
            m_message.frame.origin = CGPointMake(m_photo.frame.origin.x + m_photo.frame.width + pad, buttom)

            m_message.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_receive_nor"), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_receive_press"), forState: .Highlighted)
        }
        
        if msg.m_info.time == 0 {
            m_status.hidden = false
            m_status.frame.size = CGSizeMake(statusSize, statusSize)
            m_status.frame.origin = CGPointMake(m_message.frame.origin.x - statusSize, buttom + m_message.frame.height/2-statusSize/2)
            m_status.reloadStatus(sending ? .Sending : .Fail)
        }
        else {
            m_status.reloadStatus(.Success)
            m_status.hidden = true
        }
    }
}

class ConversationView: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ConvDelegate {
    
    var m_conv:Conversation? = nil
    var m_sendings = Dictionary<Int, Bool>()
    
    @IBOutlet weak var m_text: UITextField!
    @IBOutlet weak var m_messegesTable: UITableView!
    @IBOutlet weak var m_toolBar: UIView!
    
    @IBAction func SendMessege(sender: AnyObject) {
        let messege = m_text.text
        if messege?.characters.count > 0 {
            m_text.text = nil;
            m_conv?.sendMessage(userInfo.userID, message: messege!, type: .Msg_Str)
        }
    }
    
    func MsgSend(idx: Int) {
        let cell = m_messegesTable.cellForRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0)) as? MsgCell
        m_sendings[idx] = true
        cell?.startLoading()
    }
    
    func MsgSentSuccess(idx: Int) {
        let cell = m_messegesTable.cellForRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0)) as? MsgCell
        m_sendings.removeValueForKey(idx)
        cell?.stopLoading(true)
    }
    
    func MsgSentFail(idx: Int) {
        let cell = m_messegesTable.cellForRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0)) as? MsgCell
        m_sendings[idx] = false
        cell?.stopLoading(false)
    }
    
    func scrollToButtom() {
        if m_conv!.numMessages() > 0 {
            let lastMsg = m_conv!.numMessages() - 1
            let lastIdx = NSIndexPath(forRow: lastMsg, inSection: 0)
            self.m_messegesTable.scrollToRowAtIndexPath(lastIdx, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func ConvUpdated() {
        self.m_messegesTable.reloadData()
        scrollToButtom()
    }
    
    var originOffset:CGFloat = 0
    
    func keyboardWillChangeFrame(notify:NSNotification) {
        // 1.取得弹出后的键盘frame
        let keyboardFrame = notify.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue
    
        // 2.键盘弹出的耗时时间
        let duration = notify.userInfo![UIKeyboardAnimationDurationUserInfoKey]?.floatValue
    
        // 3.键盘变化时，view的位移，包括了上移/恢复下移
        let transformY = keyboardFrame!.origin.y - self.view.frame.size.height;
        
        if originOffset == 0 {
            originOffset = m_messegesTable.contentInset.top
        }

        print(m_messegesTable.contentSize, m_messegesTable.contentOffset, m_messegesTable.contentInset)
        
        //m_messegesTable.contentOffset.y += transformY
        let newOffset = originOffset - transformY
        m_messegesTable.contentInset = UIEdgeInsetsMake(newOffset, 0, 0, 0)
        m_messegesTable.contentOffset.y = -newOffset
        
        UIView.animateWithDuration(Double(duration!), animations: {()->Void in
            self.view.transform = CGAffineTransformMakeTranslation(0, transformY)
        })
    }
    
    func keyboardDidShow(notify:NSNotification) {
        self.scrollToButtom()
    }
    
    func keyboardWillShow(notify:NSNotification) {
        let kbFrame = notify.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        let endHeight = m_messegesTable.contentSize.height + kbFrame.size.height
        m_messegesTable.contentSize = CGSizeMake(m_messegesTable.contentSize.width, endHeight)
        m_messegesTable.contentOffset = CGPointMake(0, m_toolBar.frame.origin.y)
    }
    
    func keyboardWillHide(notify:NSNotification) {
        let kbFrame = notify.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        let endHeight = m_messegesTable.contentSize.height - kbFrame.size.height
        m_messegesTable.contentSize = CGSizeMake(m_messegesTable.contentSize.width, endHeight)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_messegesTable.registerClass(MsgCell.classForCoder(), forCellReuseIdentifier: "MsgCell")
        m_conv?.m_delegate = self
        self.title = m_conv?.getConvName()
        
        // 设置虚拟键盘监听器
        let notifier = NSNotificationCenter.defaultCenter()
        notifier.addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        notifier.addObserver(self, selector: Selector("keyboardDidShow:"), name: UIKeyboardDidShowNotification, object: nil)
        
        // 设置TextField文字左间距
        m_text.leftView = UIView(frame: CGRectMake(0, 0, 8, 0))
        m_text.leftViewMode = .Always
        
        // 设置信息输入框的代理
        m_text.delegate = self;
        
        scrollToButtom()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.viewDidDisappear(animated)
        m_conv?.m_delegate = nil
        m_conv?.m_newMsg = false
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_conv!.numMessages()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return m_conv!.m_messages[indexPath.row].getHeight(m_messegesTable.contentSize.width)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MsgCell", forIndexPath: indexPath) as! MsgCell
        let msg = m_conv!.m_messages[indexPath.row]
        let sending = m_sendings[indexPath.row] == nil ? false : m_sendings[indexPath.row]
        cell.reload(msg, sending: sending!, width: m_messegesTable.contentSize.width)
        cell.m_father = self
        return cell
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        m_text.endEditing(true)
    }
}
