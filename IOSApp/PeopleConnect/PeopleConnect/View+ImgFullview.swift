//
//  View+PostImgFullview.swift
//  PeopleConnect
//
//  Created by apple on 18/12/28.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

class ImgPageView:UIView {
    var m_imgView:UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        m_imgView = UIImageView(frame: CGRectZero)
        addSubview(m_imgView!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reload(rect:CGRect, image:UIImage) {
        let xScale = rect.width / image.size.width
        let yScale = rect.height / image.size.height
        let scale = (xScale > yScale ? yScale : xScale)
        let newImgSize = CGSizeMake(image.size.width*scale, image.size.height*scale)
        
        self.frame = rect
        m_imgView?.image = image
        m_imgView?.frame.origin = CGPointMake((rect.width-newImgSize.width)*0.5, (rect.height-newImgSize.height)*0.5)
        m_imgView?.frame.size = newImgSize
    }
}

class ImgFullview:UIView, UIScrollViewDelegate {
    var m_scroll:UIScrollView?
    var m_pageCtrl:UIPageControl?
    var m_pages = Array<ImgPageView>()
    var m_numPages:Int = 0
    var m_curPage:Int = 0
    
    func tap() {
        UIView.animateWithDuration(0.3,
            animations: { ()->Void in
                self.backgroundColor = UIColor.clearColor()
                self.m_pageCtrl?.hidden = true
            },
            completion: { (finished:Bool)->Void in
                self.removeFromSuperview()
        })
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.blackColor()
        self.userInteractionEnabled = true

        // 添加子视图
        let tap = UITapGestureRecognizer(target: self, action: Selector("tap"))
        m_scroll = UIScrollView(frame: self.bounds)
        m_scroll?.delegate = self
        m_scroll?.pagingEnabled = true
        m_scroll?.scrollEnabled = true
        m_scroll?.userInteractionEnabled = true
        m_scroll?.showsHorizontalScrollIndicator = false
        m_scroll?.showsVerticalScrollIndicator = false
        m_scroll?.addGestureRecognizer(tap)
        self.addSubview(m_scroll!)

        // 页面控制
        let screenWidth = UIScreen.mainScreen().bounds.width
        m_pageCtrl = UIPageControl(frame: CGRectMake(0, self.frame.height-40, screenWidth, 20))
        m_pageCtrl?.pageIndicatorTintColor = UIColor.grayColor()
        m_pageCtrl?.currentPageIndicatorTintColor = UIColor.whiteColor()
        self.addSubview(m_pageCtrl!)
        
        for _ in 0...8 {
            m_pages.append(ImgPageView(frame: CGRectZero))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        m_curPage = Int(scrollView.contentOffset.x / self.frame.width)
        m_pageCtrl!.currentPage = m_curPage;
    }
    
    func show(images:Array<UIImage>, index:Int, sender:UIImageView) {
        let numPages = images.count
        
        m_pageCtrl?.currentPage = index
        m_pageCtrl?.numberOfPages = numPages
        m_scroll?.contentSize = CGSizeMake(frame.width*CGFloat(numPages), frame.height)
        
        let window = UIApplication.sharedApplication().windows[0]
        
        // 解除隐藏
        window.addSubview(self)
        window.bringSubviewToFront(self)
        // 清空
        for subView in (m_scroll?.subviews)! {
            subView.removeFromSuperview()
        }
        // 添加子视图
        if numPages == 1 {
            m_pageCtrl?.removeFromSuperview()
        }
        
        for page in m_pages {
            page.removeFromSuperview()
        }
        
        for var i=0; i<numPages; i++ {
            let pageView = m_pages[i]
            m_scroll?.addSubview(pageView)
            
            // 转换Frame
            let pageRect = CGRectMake(CGFloat(i)*self.frame.width, 0, self.frame.width, self.frame.height)
            sender.superview?.convertRect(sender.frame, toView: window)
            pageView.reload(pageRect, image: images[i])
            
            if i == index {
                UIView.animateWithDuration(0.3, animations: {()->Void in
                    self.backgroundColor = UIColor.blackColor()
                    self.m_pageCtrl?.hidden = false
                    //imgView.updateOriginRect
                })
            }
            else {
                //imgView.updateOriginRect
            }
        }
        
        // 更新offset
        let offset = m_scroll?.contentOffset
        m_scroll?.contentOffset = CGPointMake(CGFloat(index) * frame.width, offset!.y)
    }
}