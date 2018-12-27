//
//  MessegeView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class MsgCell: UITableViewCell {
    var m_profile = UIButton(frame: CGRectZero)
    var m_message = UIButton(frame: CGRectZero)
    var m_time    = UILabel(frame: CGRectZero)
    
    var m_info:MsgInfo? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    func initSubviews() {
        addSubview(m_profile)
        
        m_message.titleLabel?.font = msgFont
        m_message.titleLabel?.numberOfLines = 0
        m_message.titleLabel?.lineBreakMode = .ByWordWrapping
        m_message.contentEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
        addSubview(m_message)
        
        addSubview(m_time)
    }
    
    func reload(msg:MsgInfo, width:CGFloat) {
        let pad:CGFloat = 8
        let pSize:CGFloat = 40
        let textGap:CGFloat = 20
        let maxTextSize = CGSizeMake(width - pSize*2 - pad * 4, CGFloat(MAXFLOAT))
        let textSize = getMsgSize(msg.data, maxSize: maxTextSize, font: msgFont)
        let textBubSize = CGSizeMake(textSize.width + textGap*2, textSize.height + textGap*2)
        
        m_info = msg
        
        m_profile.setImage(UIImage(named: "default_profile"), forState: .Normal)
        m_message.setTitle(msg.data, forState: .Normal)
        
        m_profile.frame.size = CGSizeMake(pSize, pSize)
        m_message.frame.size = CGSizeMake(textBubSize.width, (textBubSize.height > 40 ? textBubSize.height : 40))
        
        if msg.from == userInfo.userID {
            m_profile.frame.origin = CGPointMake(width - pad - pSize, pad)
            m_message.frame.origin = CGPointMake(m_profile.frame.origin.x - textBubSize.width - pad, pad)

            m_message.setTitleColor(UIColor.lightTextColor(), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_send_nor"), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_send_press"), forState: .Highlighted)
        }
        else {
            m_profile.frame.origin = CGPointMake(pad, pad)
            m_message.frame.origin = CGPointMake(m_profile.frame.origin.x + m_profile.frame.width + pad, pad)

            m_message.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_receive_nor"), forState: .Normal)
            m_message.setBackgroundImage(UIImage.resizableImage("chat_receive_press"), forState: .Highlighted)
        }
    }
}

class ConversationView: UIViewController, UITableViewDataSource, UITableViewDelegate, MsgDelegate {
    
    var m_conversastion:Conversation? = nil
    
    @IBOutlet weak var m_text: UITextField!
    @IBOutlet weak var m_messegesTable: UITableView!
    
    @IBAction func SendMessege(sender: AnyObject) {
        let messege = m_text.text
        if messege?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            httpSendMessege(m_conversastion!.m_id, messege: messege!)
        }
    }
    
    func MsgUpdated() {
        self.m_messegesTable.reloadData()
        let lastMsg = msgData.m_conversations.count - 1
        let lastIdx = NSIndexPath(forRow: lastMsg, inSection: 0)
        self.m_messegesTable.scrollToRowAtIndexPath(lastIdx, atScrollPosition: .Bottom, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msgData.m_delegates.append(self)
        m_messegesTable.registerClass(MsgCell.classForCoder(), forCellReuseIdentifier: "MsgCell")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_conversastion!.m_messeges.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let msg = m_conversastion?.m_messeges[indexPath.row]
        let maxTextSize = CGSizeMake(m_messegesTable.contentSize.width - 40*2 - 8*4, CGFloat(MAXFLOAT))
        let textSize = getMsgSize((msg?.data)!, maxSize: maxTextSize, font: msgFont)
        let textHeight = textSize.height + 20 * 2
        return (textHeight > 40 ? textHeight : 40) + 8
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MsgCell", forIndexPath: indexPath) as! MsgCell
        let messege = m_conversastion!.m_messeges[indexPath.row]
        cell.reload(messege, width: m_messegesTable.contentSize.width)
        return cell
    }
}
