//
//  View+Loading.swift
//  PeopleConnect
//
//  Created by apple on 18/12/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

var gLoadingView = LoadingAlert(frame: UIScreen.mainScreen().bounds)

protocol CounterDelegate {
    func counterFinished()->Void
}

class LoadingAlert:UIView {
    var m_indicator = UIActivityIndicatorView()
    var m_isStart = false

    var m_counterText = UILabel(frame: CGRectZero)
    var m_counter:NSTimer? = nil
    var m_counts:Int = 0
    var m_delegate:CounterDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blackColor()
        self.alpha = 0.6
        
        m_counterText.font = UIFont.systemFontOfSize(50)
        m_counterText.textColor = UIColor.whiteColor()
        m_counterText.textAlignment = .Center
        m_counterText.hidden = true
        self.addSubview(m_counterText)
        
        m_indicator.hidden = true
        m_indicator.activityIndicatorViewStyle = .WhiteLarge
        self.addSubview(m_indicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func counting() {
        print(m_counts)
        m_counts--
        if m_counts == 0 {
            m_counter?.invalidate()
            m_counter = nil
            self.removeFromSuperview()
            m_delegate?.counterFinished()
            m_delegate = nil
        }
        else {
            m_counterText.text = String(m_counts)
        }
    }
    
    func setupCounting(numSeconds:Int, delegate:CounterDelegate) {
        let winWidth = UIScreen.mainScreen().bounds.width
        let winHeight = UIScreen.mainScreen().bounds.height
        
        let window = UIApplication.sharedApplication().windows[0]
        
        // 解除隐藏
        window.addSubview(self)
        window.bringSubviewToFront(self)
        
        m_indicator.hidden = true

        //-----设置counter-----
        let textSize:CGFloat = 80
        m_counterText.frame = CGRectMake((winWidth-textSize)/2, (winHeight-textSize)/2, textSize, textSize)
        
        m_counts = numSeconds
        m_delegate = delegate
    }
    
    func startCounting() {
        m_counter = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("counting"), userInfo: nil, repeats: true)
        m_counter?.fire()
        m_counterText.hidden = false
        m_counterText.text = String(m_counts)
    }
    
    func stopCounting() {
        m_counter?.invalidate()
        m_counter = nil
        m_counts = 0
        m_delegate = nil
        self.removeFromSuperview()
    }
    
    func startLoading() {
        let window = UIApplication.sharedApplication().windows[0]
        
        // 解除隐藏
        window.addSubview(self)
        window.bringSubviewToFront(self)

        //-----设置指示器-----
        m_indicator.hidden = false
        m_indicator.center = self.center

        //开始动画
        m_indicator.startAnimating()
        
        m_counterText.hidden = true
        
        m_isStart = true
    }
    
    func stopLoading() {
        //停止动画
        m_indicator.stopAnimating()
        //将弹出框从父view删除
        self.removeFromSuperview()
        m_isStart = false
    }
}