//
//  AppDelegate.swift
//  PeopleConnect
//
//  Created by apple on 18/11/7.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // MARK: - CoreData
    lazy var context: NSManagedObjectContext = {
        //1、创建模型对象
        //获取模型路径
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")
        //根据模型文件创建模型对象
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        //2、创建持久化存储助理：数据库
        //利用模型对象创建助理对象
        let store = NSPersistentStoreCoordinator(managedObjectModel: model!)
        //数据库的名称和路径
        let docStr = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last
        let sqlPath = docStr?.stringByAppendingString("/coreData.sqlite")
        let sqlUrl = NSURL(fileURLWithPath: sqlPath!)
        
        //设置数据库相关信息 添加一个持久化存储库并设置类型和路径，NSSQLiteStoreType：SQLite作为存储库
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
        do {
            try store.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sqlUrl, options: options)
        }
        catch {
        }
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = store
        return context
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

