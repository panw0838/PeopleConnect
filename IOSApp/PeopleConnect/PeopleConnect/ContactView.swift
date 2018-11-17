//
//  ContactView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/17.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

let holding = UIAlertController(title: "加载中", message: "", preferredStyle: .Alert)

class ContactView: UIViewController {
    
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_background: UIImageView!
    
    var m_contact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        m_name.text = m_contact.name
        m_profile.image = UIImage(named: "default_profile")
    }
    
    @IBAction func AddContact() {
        let alert = UIAlertController(title: "添加联系人", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default,
            handler: {
                action in
                self.m_contact.flag = 2
                self.httpAddContact(self.m_contact.user, flag: self.m_contact.flag, name: self.m_contact.name)
        })
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func RemContact(sender: AnyObject) {
    }
}
