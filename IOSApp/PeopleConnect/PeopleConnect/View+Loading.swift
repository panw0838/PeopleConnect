//
//  View+Loading.swift
//  PeopleConnect
//
//  Created by apple on 18/12/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

class LoadingAlert:NSObject {
    var m_parent:UIView? = nil
    var m_alert:UIView? = nil
    var m_indicator:UIActivityIndicatorView? = nil
    var m_isStart = false
    
    init(parent:UIView) {
        m_parent = parent
    }
    
    func startLoading() {
        let winWidth = UIScreen.mainScreen().bounds.width
        let winHeight = UIScreen.mainScreen().bounds.height
        
        let alert = UIView()
        alert.backgroundColor = UIColor.blackColor()
        alert.alpha = 0.6
        //将弹出框加入到父view
        m_parent?.addSubview(alert)
        alert.frame = CGRectMake(0, 0, winWidth, winHeight)

        //-----设置指示器-----
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .WhiteLarge
        alert.addSubview(indicator)
        indicator.center = alert.center

        //开始动画
        indicator.startAnimating()
        
        m_alert = alert
        m_indicator = indicator
        m_isStart = true
    }
    
    func stopLoading() {
        //停止动画
        m_indicator?.stopAnimating()
        //将弹出框从父view删除
        m_alert?.removeFromSuperview()
        m_isStart = false
    }
}