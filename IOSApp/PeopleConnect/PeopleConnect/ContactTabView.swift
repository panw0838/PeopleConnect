//
//  ContactTabView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/14.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class ContactTabView: UIViewController, UITabBarDelegate {
    
    @IBOutlet weak var m_tabsBar: UITabBar!
    @IBOutlet weak var m_contents: UIView!
    
    var m_subViews:Array<ContactsView> = Array<ContactsView>()
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        let idx = item.tag
        if idx == contactsData.numMainTags() {
            // request new tag
        }
        else {
            //m_contents.addSubview(m_subViews[idx])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contactsData.loadContacts()
        m_tabsBar.items?.removeAll()
        m_subViews.removeAll()
        var tagIdx = 0
        for tag in contactsData.m_tags {
            let newTab:UITabBarItem = UITabBarItem.init(title: tag.tagName, image: nil, tag: tagIdx)
            let newSub:ContactsView = ContactsView()
            newSub.setTabIndex(tagIdx)
            m_tabsBar.items?.append(newTab)
            m_subViews.append(newSub)
            tagIdx++
        }
        let addNewTag:UITabBarItem = UITabBarItem.init(tabBarSystemItem: .More, tag: tagIdx)
        m_tabsBar.items?.append(addNewTag)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func requestContacts() {
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
        http.postRequest("contacts", params: params,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let html: String = String.init(data: response as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Error")) {
                    print("%s", html)
                }
                else {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(response as! NSData, options: .MutableContainers) as? [String:[[String:AnyObject]]] {
                        contacts.removeAll()
                        userTags.removeAll()
                        for case let contactObj in json!["contacts"]! {
                            if let contact = ContactInfo(json: contactObj) {
                                contacts.append(contact)
                            }
                        }
                        for case let tagObj in json!["tags"]! {
                            if let tag = TagInfo(json: tagObj) {
                                userTags.append(tag)
                            }
                        }
                        contactsData.loadContacts()
                        //self.collectionView?.reloadData()
                    }
                }
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
        })
    }
}