//
//  View+PostImgPreview.swift
//  PeopleConnect
//
//  Created by apple on 18/12/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class ImgCellView: UIImageView {
    var m_index = 0
}

struct PreviewLayout {
    var xNumBlk:Int = 0
    var yNumBlk:Int = 0
    var scale:Int = 1
    
    init() {
    }
    
    init(_xNumBlk:Int, _yNumBlk:Int, _scale:Int) {
        xNumBlk = _xNumBlk
        yNumBlk = _yNumBlk
        scale = _scale
    }
}

class ImgPreview: UIView {
    let m_gap:CGFloat = 5.0
    var m_post:Post? = nil
    var m_preImgs = Array<ImgCellView>()
    var m_pattern = Array<PreviewLayout>()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        for i in 0...8 {
            let layout = PreviewLayout()
            let img = ImgCellView(frame: CGRectZero)
            img.m_index = i
            img.clipsToBounds = true
            img.contentMode = .ScaleAspectFill
            m_preImgs.append(img)
            m_pattern.append(layout)
            self.addSubview(img)
        }
    }

    func reload(post:Post) {
        m_post = post
        if post.m_imgKeys.count == 0 {
            self.hidden = true
        }
        else {
            initPreviewPattern(post.m_imgKeys.count)
            
            for preImg in m_preImgs {
                preImg.hidden = true
            }
            
            let fullSize = self.frame.height
            let blkSize = (self.frame.height - m_gap) / 2
            let step = blkSize + m_gap
            
            for (idx, imgKey) in post.m_imgKeys.enumerate() {
                let layout = m_pattern[idx]
                let size = (layout.scale == 1 ? blkSize : fullSize)
                m_preImgs[idx].hidden = false
                m_preImgs[idx].image = (previews[imgKey] == nil ? UIImage(named: "loading") : previews[imgKey])
                m_preImgs[idx].frame = CGRectMake(CGFloat(layout.xNumBlk)*step, CGFloat(layout.yNumBlk)*step, size, size)
            }
        }
    }
    
    func getFullImg(idx:Int) {
        http.getFile((m_post?.m_imgUrls[idx])!,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                //let data = response as! NSData
                //cell.m_preview.image = UIImage(data: data)
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            }
        )
    }
    
    func initPreviewPattern(numImgs:Int) {
        switch numImgs {
        case 1:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            break
        case 2:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 2)
            break
        case 3:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 2)
            m_pattern[2] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 2)
            break
        case 4:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 2)
            m_pattern[2] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            break
        case 5:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 2)
            m_pattern[2] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            m_pattern[4] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 1, _scale: 1)
            break
        case 6:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 2)
            m_pattern[2] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            m_pattern[4] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 1, _scale: 1)
            m_pattern[5] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 1, _scale: 1)
            break
        case 7:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 1)
            m_pattern[2] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[4] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            m_pattern[5] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 1, _scale: 1)
            m_pattern[6] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 1, _scale: 1)
            break
        case 8:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 1)
            m_pattern[2] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[4] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            m_pattern[5] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 1, _scale: 1)
            m_pattern[6] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 1, _scale: 1)
            m_pattern[7] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 1, _scale: 1)
            break
        case 9:
            m_pattern[0] = PreviewLayout(_xNumBlk: 0, _yNumBlk: 0, _scale: 2)
            m_pattern[1] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 0, _scale: 1)
            m_pattern[2] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 0, _scale: 1)
            m_pattern[3] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 0, _scale: 1)
            m_pattern[4] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 0, _scale: 1)
            m_pattern[5] = PreviewLayout(_xNumBlk: 2, _yNumBlk: 1, _scale: 1)
            m_pattern[6] = PreviewLayout(_xNumBlk: 3, _yNumBlk: 1, _scale: 1)
            m_pattern[7] = PreviewLayout(_xNumBlk: 4, _yNumBlk: 1, _scale: 1)
            m_pattern[8] = PreviewLayout(_xNumBlk: 5, _yNumBlk: 1, _scale: 1)
            break
        default:
            break
        }
    }
}
