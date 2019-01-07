//
//  Widget+ContactCell.swift
//  PeopleConnect
//
//  Created by apple on 19/1/7.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

class ContactCell: UICollectionViewCell {
    var m_image  = UIImageView(frame: CGRectZero)
    var m_name   = UILabel(frame: CGRectZero)
    var m_id:UInt64 = 0
    var m_father:ContactsView?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        m_image.layer.cornerRadius = 10
        m_image.layer.masksToBounds = true
        m_name.font = ContactNameFont
        m_name.numberOfLines = 0
        m_name.lineBreakMode = .ByWordWrapping
        m_name.textAlignment = .Center
        addSubview(m_image)
        addSubview(m_name)
    }
    
    func setupSubViews() {
        let width = self.frame.width
        let photoSize:CGFloat = 50
        m_image.frame = CGRectMake((width-photoSize)/2, (width-photoSize)/2, photoSize, photoSize)
        m_name.frame = CGRectMake(0, width, width, ContactNameHeight)
    }
    
    func reload(cID:UInt64) {
        m_id = cID
        setupSubViews()
        m_image.image = getPhoto(m_id)
        m_name.text   = getName(m_id)
    }
    
    func tap() {
        let contact = contactsData.m_contacts[m_id]
        if contact?.flag == 0 {
            ContactView.ContactID = m_id
            m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
        }
        else {
            let alert = UIAlertController(title: contact?.name, message: "", preferredStyle: .ActionSheet)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            
            let msgAction = UIAlertAction(title: "发信息", style: .Default, handler: { action in
                self.m_father?.m_convID = self.m_id
                self.m_father?.performSegueWithIdentifier("StartConversation", sender: nil)
            })
            
            let callAction = UIAlertAction(title: "打电话", style: .Default, handler: { action in
            })
            
            let detailAction = UIAlertAction(title: "查看资料", style: .Default, handler: { action in
                ContactView.ContactID = self.m_id
                self.m_father?.performSegueWithIdentifier("ShowContact", sender: nil)
            })
            
            alert.addAction(noAction)
            alert.addAction(msgAction)
            alert.addAction(callAction)
            alert.addAction(detailAction)
            
            self.m_father?.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

class ActionCell:ContactCell {
    var m_act:TagAction?
    var m_tag:Tag?
    
    func reloadAction(action:TagAction, tag:Tag?) {
        m_act = action
        m_tag = tag
        
        setupSubViews()
        m_image.image = UIImage(named: TagActionsImgs[m_act!]!)
        m_name.text   = TagActionsNames[m_act!]!
    }
    
    func tagNameChanged(sender:UITextField) {
        let alert:UIAlertController = self.m_father!.presentedViewController as! UIAlertController
        let tagName:String = (alert.textFields?.first?.text)!
        let okAction:UIAlertAction = alert.actions.last!
        let nameSize = tagName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        okAction.enabled = (nameSize > 0 && nameSize < 18)
    }

    override func tap() {
        switch m_act! {
        case .MoveMember:
            m_father?.performSegueWithIdentifier("ShowMoveMember", sender: m_tag)
            break
        case .AddTag:
            let alert = UIAlertController(title: "添加标签", message: "添加子标签到 "+m_tag!.m_tagName, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Default,
                handler: { action in
                    httpAddTag(self.m_tag!.m_tagID, name: (alert.textFields?.first?.text)!)})
            alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
                textField.placeholder = "标签名称"
                textField.addTarget(self, action: Selector("tagNameChanged:"), forControlEvents: .EditingChanged)
            }
            okAction.enabled = false
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.m_father?.presentViewController(alert, animated: true, completion: nil)
            break
        case .DelTag:
            let alert = UIAlertController(title: "删除标签", message: m_tag!.m_tagName, preferredStyle: .Alert)
            let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
            let okAction = UIAlertAction(title: "确定", style: .Destructive,
                handler: { action in
                    httpRemTag(self.m_tag!)
            })
            alert.addAction(noAction)
            alert.addAction(okAction)
            self.m_father?.presentViewController(alert, animated: true, completion: nil)
            break
        case .SearchCell:
            checkContactsBookPrivacy()
            break
        case .SearchConn:
            httpGetSuggestContacts()
            break
        case .SearchFace:
            m_father?.startFaceToFace()
            break
        case .SearchNear:
            m_father?.RefreshNearby()
            break
        default:
            break
        }
    }
}