//
//  User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import CoreLocation

struct GroupInfo {
    var id:UInt32 = 0
    var name:String = ""
}

struct UserInfo {
    var userID : UInt64 = 0
    var countryCode: Int = 0
    var cellNumber : String = ""
    var mailAddr : String = ""
    var qqNumber : String = ""
    var account : String = ""
    
    var userName : String = ""
    var password : String = ""
    var config : UInt64 = 0
    var deviceID : String = ""
    var ipAddress : String = ""
    
    var msgSyncID : UInt64 = 0
    var x : Double = 0
    var y : Double = 0
    
    var groups = Array<GroupInfo>()
}

var userInfo:UserInfo = UserInfo()
var userData = User()

protocol UpdateLocationDelegate {
    func UpdateLocationSuccess()->Void
    func UpdateLocationFail()->Void
}

class User: NSObject, CLLocationManagerDelegate {
    
    let m_locMgr = CLLocationManager()
    var m_delegate:UpdateLocationDelegate?
    
    override init() {
        super.init()
        m_locMgr.delegate = self
        m_locMgr.desiredAccuracy = 100
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        let coord = loc?.coordinate
        userInfo.x = (coord?.latitude)!
        userInfo.y = (coord?.longitude)!
        manager.stopUpdatingLocation()
        m_delegate?.UpdateLocationSuccess()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        m_delegate?.UpdateLocationFail()
    }
        
    func startLocate(delegate:UpdateLocationDelegate?) {
        m_delegate = delegate
        if m_locMgr.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
            m_locMgr.requestWhenInUseAuthorization()
        }
        m_locMgr.startUpdatingLocation()
    }
    
    func setCurUser() {
        let user = NSUserDefaults()
        let oldUserObj = user.objectForKey("user")
        
        if oldUserObj != nil {
            let oldUID = (oldUserObj as! NSNumber).unsignedLongLongValue
            if userInfo.userID != oldUID {
                user.removeObjectForKey("msgSyncID")
            }
        }
        
        user.setObject(NSNumber(unsignedLongLong: userInfo.userID), forKey: "user")
        user.setObject(NSNumber(integer: userInfo.countryCode), forKey: "code")
        user.setObject(userInfo.cellNumber, forKey: "cell")
        user.setObject(userInfo.password, forKey: "pass")
    }
    
    func setMsgSyncID(syncID:UInt64) {
        let user = NSUserDefaults()
        userInfo.msgSyncID = syncID
        // todo, always sync messages for testing
        //user.setObject(NSNumber(unsignedLongLong: syncID), forKey: "msgSyncID")
        user.setObject(NSNumber(unsignedLongLong: 0), forKey: "msgSyncID")
    }
    
    func getCurUser()->Bool {
        let user = NSUserDefaults()
        let uIDObj = user.objectForKey("user")
        let codeObj = user.objectForKey("code")
        let cellObj = user.objectForKey("cell")
        let passObj = user.objectForKey("pass")
        
        if uIDObj != nil && codeObj != nil && cellObj != nil && passObj != nil {
            userInfo.userID = (uIDObj as! NSNumber).unsignedLongLongValue
            userInfo.countryCode = (codeObj as! NSNumber).integerValue
            userInfo.cellNumber = cellObj as! String
            userInfo.password = passObj as! String
            
            let msgSyncObj = user.objectForKey("msgSyncID")
            if msgSyncObj != nil {
                userInfo.msgSyncID = (msgSyncObj as! NSNumber).unsignedLongLongValue
            }
            return true
        }
        else {
            return false
        }
    }
}