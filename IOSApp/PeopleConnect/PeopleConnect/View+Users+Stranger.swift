//
//  View+Users+Stranger.swift
//  PeopleConnect
//
//  Created by apple on 19/1/7.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

extension UsersView {
    
    func showError(title:String, err:String?) {
        let alert = UIAlertController(title: title, message: err, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func ActionSearchCell() {
        let err = checkContactsBookPrivacy()
        if err.characters.count == 0 {
            gLoadingView.startLoading()
            let (names, codes, cells) = getContactsBook()
            httpGetCellContacts(names, codes: codes, cells: cells,
                passed: {()->Void in
                    gLoadingView.stopLoading()
                },
                failed: {(err:String?)->Void in
                    gLoadingView.stopLoading()
            })
        }
        else {
            showError("搜索手机联系人", err: err)
        }
    }
    
    func ActionSearchConn() {
        gLoadingView.startLoading()
        httpGetSuggestContacts(
            {()->Void in
                gLoadingView.stopLoading()
            },
            failed: {(err:String?)->Void in
                gLoadingView.stopLoading()
            })
    }
    
    func ActionSearchFace() {
        gLoadingView.setupCounting(11, invokeSeconds: 11, delegate: self)
        userData.startLocate(self)
        m_searchNear = false
        contactsData.m_faceUsers.clearContacts()
    }
    
    func ActionSearchLike() {
        gLoadingView.startLoading()
        contactsData.m_likeUsers.clearContacts()
        httpGetBothLikeUsers(
            {()->Void in
                gLoadingView.stopLoading()
            },
            failed: {(err:String?)->Void in
                gLoadingView.stopLoading()
        })
    }
    
    func ActionSearchNear() {
        gLoadingView.startLoading()
        userData.startLocate(self)
        m_searchNear = true
        contactsData.m_nearUsers.clearContacts()
    }
    
    func counterFinished() {
        httpGetFaceUsers(
            {()->Void in
                let found = contactsData.m_faceUsers.m_members.count
                let foundMsg = (found == 0 ? "未找到好友" : "找到" + String(found) + "好友")
                let alert = UIAlertController(title: "面对面加好友", message: foundMsg, preferredStyle: UIAlertControllerStyle.Alert)
                let cancelAction = UIAlertAction(title: "完成搜索", style: UIAlertActionStyle.Cancel,
                    handler: { action in
                        httpDidFaceUsers()
                })
                let okAction = UIAlertAction(title: "继续搜索", style: UIAlertActionStyle.Default,
                    handler: { action in
                        gLoadingView.setupCounting(11, invokeSeconds: 11, delegate: self)
                        gLoadingView.startCounting()
                })
                alert.addAction(cancelAction)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
                
            },
            failed: {(err:String?)->Void in
                self.showError("面对面加好友", err: err)
        })
    }
    
    func counterInvoke() {
    }
    
    func UpdateLocationSuccess() {
        if m_searchNear {
            httpGetNearbyUsers(
                {()->Void in
                    gLoadingView.stopLoading()
                },
                failed: nil)
            m_searchNear = false
        }
        else {
            httpRegFaceUsers(
                {()->Void in
                    gLoadingView.startCounting()
                },
                failed: {(err:String?)->Void in
                    gLoadingView.stopCounting()
            })
        }
    }
    
    func UpdateLocationFail() {
        gLoadingView.stopLoading()
        m_searchNear = false
    }
}