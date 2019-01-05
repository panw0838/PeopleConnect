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
    func counterInvoke()->Void
}

class LoadingAlert:UIView {
    var m_indicator = UIActivityIndicatorView()
    var m_isStart = false

    var m_counterText = UILabel(frame: CGRectZero)
    var m_counter:NSTimer? = nil
    var m_counts:Int = 0
    var m_step:Int = 0
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
        m_counterText.text = String(m_counts)
        if m_counts <= 0 {
            m_counter?.invalidate()
            m_counter = nil
            self.removeFromSuperview()
            m_delegate?.counterFinished()
            m_delegate = nil
        }
        else {
            if (m_counts % m_step) == 0 {
                print(m_counts)
                m_delegate?.counterInvoke()
            }
        }
        m_counts--
    }
    
    func setupCounting(totalSeconds:Int, invokeSeconds:Int, delegate:CounterDelegate) {
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
        m_counterText.text = String(m_counts)

        m_step = invokeSeconds
        m_counts = totalSeconds
        m_delegate = delegate
    }
    
    func startCounting() {
        m_counterText.hidden = false
        //获取全局队列
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //创建一个定时器，并将定时器的任务交给全局队列执行(并行，不会造成主线程阻塞)
        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        // 设置触发的间隔时间
        dispatch_source_set_timer(timer, dispatch_walltime(nil, 0), NSEC_PER_SEC, 0);
        //1.0 * NSEC_PER_SEC  代表设置定时器触发的时间间隔为1s
        //0 * NSEC_PER_SEC    代表时间允许的误差是 0s
        
        //block内部 如果对当前对象的强引用属性修改 应该使用__weak typeof(self)weakSelf 修饰  避免循环调用
        //__weak typeof(self)weakSelf = self;
        //weak var weakSelf = self
        //设置定时器的触发事件
        dispatch_source_set_event_handler(timer, {
            //1. 每调用一次 时间-1s
            print(self.m_counts)
            self.m_counts--
            //2.对timeout进行判断时间是停止倒计时，还是修改button的title
            if (self.m_counts <= 0) {
                //停止倒计时，button打开交互，背景颜色还原，title还原
                self.m_delegate?.counterFinished()
                self.m_delegate = nil
                self.m_counterText.hidden = true

                //关闭定时器
                dispatch_source_cancel(timer)
    
                //MRC下需要释放，这里不需要
                //dispatch_realse(timer)
                
                //在主线程中对button进行修改操作
                dispatch_async(dispatch_get_main_queue(), {
                    self.removeFromSuperview()
                });
            }
            else {
                if (self.m_counts % self.m_step) == 0 {
                    print("invoke")
                    self.m_delegate?.counterInvoke()
                }
                //处于正在倒计时，在主线程中刷新button上的title，时间-1秒
                dispatch_async(dispatch_get_main_queue(), {
                    self.m_counterText.text = String(self.m_counts)
                });
            }
        });
        
        dispatch_resume(timer);
        
        
        //m_counter = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("counting"), userInfo: nil, repeats: true)
        //m_counter?.fire()
        //m_counterText.hidden = false
    }
    
    func stopCounting() {
        //m_counter?.invalidate()
        //m_counter = nil
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