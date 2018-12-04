//
//  User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

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

class User {
    
    
    
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