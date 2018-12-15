//
//  User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import CoreTelephony

struct GroupInfo {
    var id:UInt32 = 0
    var name:String = ""
}

struct UserInfo {
    var userID : UInt64
    var cellNumber : String
    var mailAddr : String
    var qqNumber : String
    var account : String
    
    var userName : String
    var password : String
    var config : UInt64
    var deviceID : String
    var ipAddress : String
    
    var groups = Array<GroupInfo>()
    
    init () {
        userID = 0
        cellNumber = ""
        mailAddr = ""
        qqNumber = ""
        account = ""
        
        userName = ""
        password = ""
        config = 0
        deviceID = ""
        ipAddress = ""
    }
}

var userInfo:UserInfo = UserInfo()
var userData = User()

class User {
    func getCountryCode()->String {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        if carrier != nil {
            return "+" + carrier!.mobileCountryCode!
        }
        return "+86"
    }
    
    func loadCountryCode() {
        
    }
    
    func checkCellNumber(cell:String)->Bool {
        let cellYD = "^1(3[0-9]|4[57]|5[0-35-9]|8[0-9]|7[0678])\\d{8}$"
        let cellLT = "(^1(3[4-9]|4[7]|5[0-27-9]|7[8]|8[2-478])\\d{8}$)|(^1705\\d{7}$)"
        let cellDX = "(^1(3[0-2]|4[5]|5[56]|7[6]|8[56])\\d{8}$)|(^1709\\d{7}$)"
        let preYD = NSPredicate(format: "SELF MATCHES %s", cellYD)
        let preLT = NSPredicate(format: "SELF MATCHES %s", cellLT)
        let preDX = NSPredicate(format: "SELF MATCHES %s", cellDX)
        
        return preYD.evaluateWithObject(cell) || preLT.evaluateWithObject(cell) || preDX.evaluateWithObject(cell)
    }
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr.memory.ifa_next }
                
                let flags = Int32(ptr.memory.ifa_flags)
                let addr = ptr.memory.ifa_addr.memory
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(ptr.memory.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                if let address = String.fromCString(hostname) {
                                    addresses.append(address)
                                }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return addresses
    }
}