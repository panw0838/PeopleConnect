//
//  Observer.swift
//  PeopleConnect
//
//  Created by apple on 18/11/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

var tcp:TCPClient = TCPClient()

let Connect_Ack:UInt8 = 0
let Log_Pkg:UInt8 = 1
let Log_Act:UInt8 = 2
let Messege_Pkg:UInt8 = 3
let Messege_Ack:UInt8 = 4
let Messege_Syc:UInt8 = 5


class TCPClient:NSObject, GCDAsyncSocketDelegate {
    
    var m_socket:GCDAsyncSocket = GCDAsyncSocket()
    
    override init() {
        super.init()
        m_socket.delegate = self
        m_socket.delegateQueue = dispatch_get_main_queue()

    }
    
    func start(ip:String, port:UInt16) {
        do {
            try m_socket.connectToHost(ip, onPort: port)
        }
        catch {
            print(error)
        }
    }
    
    func stop () {
        m_socket.disconnect()
    }
    
    func logon() {
        let data = NSMutableData(bytes: [Log_Pkg, 0] as [UInt8], length: 2)
        let params: Dictionary = ["user":NSNumber(unsignedLongLong: userInfo.userID)]
        if let paramsData:NSData = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted) {
            data.appendData(paramsData)
            m_socket.writeData(data, withTimeout: 1, tag: 110)
            m_socket.readDataWithTimeout(-1, tag: 100)
        }
    }
    
    
    func sendMessege(to:UInt64, messege:String) {
        let data = NSMutableData(bytes: [Messege_Pkg, 0] as [UInt8], length: 2)
        let params: Dictionary = ["from":NSNumber(unsignedLongLong: userInfo.userID), "to":NSNumber(unsignedLongLong: to), "id":NSNumber(int: 1), "mess":messege]
        if let paramsData:NSData = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted) {
            data.appendData(paramsData)
            m_socket.writeData(data, withTimeout: 1, tag: 110)
        }
    }
    
    func socket(sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        m_socket.readDataWithTimeout(-1, tag: 110)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket, withError err: NSError?) {
        // reconnect
    }
    
    func socket(sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        // handle write
        m_socket.readDataWithTimeout(-1, tag: 000)
    }
    
    func socket(sock: GCDAsyncSocket, didReadData data: NSData, withTag tag: Int) {
        var pkgID:UInt8 = 0
        data.getBytes(&pkgID, length: 1)

        switch pkgID {
        case Connect_Ack:
            print("connect ack")
            break
        case Log_Act:
            print("log ack")
            break
        case Messege_Ack:
            print("messege ack")
            break
        case Messege_Syc:
            httpSyncMessege()
            /*
            let content = data.subdataWithRange(NSRange(location: 2, length: data.length-2))
            if let json = try? NSJSONSerialization.JSONObjectWithData(content, options: .MutableContainers) as! [String:AnyObject] {
                if let messege = MessegeInfo(json: json) {
                    messegeData.AddNewMessege(messege.from, newMessege: messege)
                    for callback in messegeCallbacks {
                        callback.MessegeUpdateUI()
                    }
                }
            }
            */
            break
        default:
            break
        }

        m_socket.readDataWithTimeout(-1, tag: 110)
    }
}

