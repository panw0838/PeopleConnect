//
//  Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/8.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

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
    }
}

func registeRequest(var userInfo : UserInfo) {
    let url: NSURL = NSURL(string: "https://192.168.0.103:8080/register")!
    let request: NSURLRequest = NSURLRequest(URL: url)
    let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?> = nil
    
    userInfo.cellNumber = "+8615821112604"
    userInfo.deviceID = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
}

func ConnectionRequest(jsonString:NSDictionary, callback: (NSDictionary, String!) -> Void) {
    let request = NSMutableURLRequest(URL: NSURL(string: "https://example.com:9222")!)

    var result = NSDictionary()

    do {
        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(jsonString, options: [])
    } catch{
        request.HTTPBody = nil
    }
    request.timeoutInterval = 20.0 //(number as! NSTimeInterval)
    request.HTTPMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("gzip", forHTTPHeaderField: "Accept-encoding")

    let configuration =
    NSURLSessionConfiguration.defaultSessionConfiguration()

    let session = NSURLSession(configuration: configuration,
        delegate: self,
        delegateQueue:NSOperationQueue.mainQueue())
    print("--------------------------------NSURLSession Request-------------------------------------------------->:\n \(jsonString)")
    print(NSDate())


    let task = session.dataTaskWithRequest(request){
        (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode != 200 {
                print("response was not 200: \(response)")
                return
            }
            else
            {
                print("response was 200: \(response)")

                print("Data for 200: \(data)")

                // In the callback you can return the data/response 
                callback(data, nil)
                return
            }
        }
        if (error != nil) {
            print("error request:\n \(error)")
            //Here you can return the error and handle it accordingly
            return
        }

    }
    task.resume()
}

func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

    if challenge.protectionSpace.authenticationMethod == (NSURLAuthenticationMethodServerTrust) {


    let serverTrust:SecTrustRef = challenge.protectionSpace.serverTrust!
    let certificate: SecCertificateRef = SecTrustGetCertificateAtIndex(serverTrust, 0)!
    let remoteCertificateData = CFBridgingRetain(SecCertificateCopyData(certificate))!
    let cerPath: String = NSBundle.mainBundle().pathForResource("example.com", ofType: "cer")!
    let localCertificateData = NSData(contentsOfFile:cerPath)!


        if (remoteCertificateData.isEqualToData(localCertificateData) == true) {
            let credential:NSURLCredential = NSURLCredential(forTrust: serverTrust)

            challenge.sender?.useCredential(credential, forAuthenticationChallenge: challenge)


            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))

        } else {

            completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
        }
    }
    else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate
    {

        let path: String = NSBundle.mainBundle().pathForResource("client", ofType: "p12")!
        let PKCS12Data = NSData(contentsOfFile:path)!


        let identityAndTrust:IdentityAndTrust = self.extractIdentity(PKCS12Data);



            let urlCredential:NSURLCredential = NSURLCredential(
                identity: identityAndTrust.identityRef,
                certificates: identityAndTrust.certArray as? [AnyObject],
                persistence: NSURLCredentialPersistence.ForSession);

            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, urlCredential);




    }
    else
    {
        completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil);
    }
}

 struct IdentityAndTrust {

    var identityRef:SecIdentityRef
    var trust:SecTrustRef
    var certArray:AnyObject
}

func extractIdentity(certData:NSData) -> IdentityAndTrust {
    var identityAndTrust:IdentityAndTrust!
    var securityError:OSStatus = errSecSuccess

    let path: String = NSBundle.mainBundle().pathForResource("client", ofType: "p12")!
    let PKCS12Data = NSData(contentsOfFile:path)!
    let key : NSString = kSecImportExportPassphrase as NSString
    let options : NSDictionary = [key : "xyz"]
    //create variable for holding security information
    //var privateKeyRef: SecKeyRef? = nil

    var items : CFArray?

     securityError = SecPKCS12Import(PKCS12Data, options, &items)

    if securityError == errSecSuccess {
        let certItems:CFArray = items as CFArray!;
        let certItemsArray:Array = certItems as Array
        let dict:AnyObject? = certItemsArray.first;
        if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {

            // grab the identity
            let identityPointer:AnyObject? = certEntry["identity"];
            let secIdentityRef:SecIdentityRef = identityPointer as! SecIdentityRef!;
            print("\(identityPointer)  :::: \(secIdentityRef)")
            // grab the trust
            let trustPointer:AnyObject? = certEntry["trust"];
            let trustRef:SecTrustRef = trustPointer as! SecTrustRef;
            print("\(trustPointer)  :::: \(trustRef)")
            // grab the cert
            let chainPointer:AnyObject? = certEntry["chain"];
            identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef, trust: trustRef, certArray:  chainPointer!);
        }
    }
    return identityAndTrust;
}
