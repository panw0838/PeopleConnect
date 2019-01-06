//
//  View+PostImgPreview.swift
//  PeopleConnect
//
//  Created by apple on 18/12/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

var gImgFullview = ImgFullview(frame: UIScreen.mainScreen().bounds)

class DelCellView: UIImageView {
    var m_index = 0
    var m_father:ImgPreview?

    func del() {
        m_father?.removeImgAtIndex(m_index)
    }
}

class ImgCellView: UIImageView {
    var m_index = 0
    var m_father:ImgPreview?
    
    func tap() {
        gImgFullview.show(m_father!.m_post!.getPreviews(), index: m_index, sender: self)
    }
    
    func tapEdit() {
        let picks = m_father!.m_picks
        if m_index < picks.count {
            gImgFullview.show(m_father!.m_picks, index: m_index, sender: self)
        }
        else {
            let navi = UINavigationController(rootViewController: m_father!.m_picker!)
            navi.delegate = m_father!.m_controller!
            m_father!.m_controller!.presentViewController(navi, animated: true, completion: nil)
        }
    }
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

class ImgPreview: UIView, ImgPickerDelegate {
    var m_post:Post? = nil
    var m_preImgs = Array<ImgCellView>()
    var m_pattern = Array<PreviewLayout>()
    // for edit
    var m_delBtns = Array<UIImageView>()
    var m_picker:ImgPicker? = nil
    var m_picks = Array<UIImage>()
    var m_controller:CreatePostView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews(true)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews(false)
    }
    
    func initSubviews(edit:Bool) {
        for i in 0...8 {
            let layout = PreviewLayout()
            let img = ImgCellView(frame: CGRectZero)
            let tapAction = edit ? "tapEdit" : "tap"
            let tap = UITapGestureRecognizer(target: img, action: Selector(tapAction))
            img.m_index = i
            img.m_father = self
            img.clipsToBounds = true
            img.contentMode = .ScaleAspectFill
            img.layer.cornerRadius = 5
            img.userInteractionEnabled = true
            img.addGestureRecognizer(tap)
            m_preImgs.append(img)
            m_pattern.append(layout)
            self.addSubview(img)
        }
        
        if edit {
            m_picker = ImgPicker(maxCount: 9)
            m_picker?.m_pickerDelegate = self
            
            for i in 0...8 {
                let del = DelCellView(frame: CGRectZero)
                let tap = UITapGestureRecognizer(target: del, action: Selector("del"))
                del.m_index = i
                del.m_father = self
                del.contentMode = .ScaleAspectFill
                del.userInteractionEnabled = true
                del.addGestureRecognizer(tap)
                m_delBtns.append(del)
                self.addSubview(del)
            }
        }
    }
    
    func removeImgAtIndex(index:Int) {
        m_picker?.removeAtIndex(index)
        m_picks.removeAtIndex(index)
        reloadEdit()
        m_controller?.updateCreateBtn()
    }
    
    func didFinishedPickImage(imgs: Array<PHAsset>) {
        let imgMgr = PHImageManager()
        let options = PHImageRequestOptions()
        
        options.deliveryMode = .HighQualityFormat
        options.networkAccessAllowed = true
        options.resizeMode = .Exact
        options.synchronous = true
        
        m_picks.removeAll()
        
        for asset in imgs {
            let tarSize = CGSizeMake(1024*4, 1024*4)
            imgMgr.requestImageForAsset(asset, targetSize: tarSize, contentMode: .AspectFill, options: options, resultHandler: {(img:UIImage?, info:[NSObject:AnyObject]?)->Void in
                self.m_picks.append(img!)
            })
        }
        
        reloadEdit()
        m_controller?.updateCreateBtn()
    }
    
    func reloadEdit() {
        let numImgs = m_picks.count == 9 ? 9 : m_picks.count + 1
        initPreviewPattern(numImgs)
        
        for preImg in m_preImgs {
            preImg.hidden = true
        }
        
        for delBtn in m_delBtns {
            delBtn.hidden = true
        }
        
        let fullSize = self.frame.height
        let blkSize = (self.frame.height - PostPreViewGap) / 2
        let step = blkSize + PostPreViewGap
        
        for var i=0; i<numImgs; i++ {
            let layout = m_pattern[i]
            let size = (layout.scale == 1 ? blkSize : fullSize)
            
            m_preImgs[i].hidden = false
            m_preImgs[i].frame = CGRectMake(CGFloat(layout.xNumBlk)*step, CGFloat(layout.yNumBlk)*step, size, size)

            if i < m_picks.count {
                let delBtnSize:CGFloat = 25
                let frame = m_preImgs[i].frame
                let btnX = frame.origin.x + frame.width - delBtnSize
                m_preImgs[i].image = m_picks[i]
                m_delBtns[i].image = UIImage(named: "remove")
                m_delBtns[i].hidden = false
                m_delBtns[i].frame = CGRectMake(btnX, frame.origin.y, delBtnSize, delBtnSize)
            }
            else {
                m_preImgs[i].image = UIImage(named: "plus")
            }
        }
    }

    func reload(post:Post) {
        m_post = post
        let numImgs = post.numImages()
        if numImgs == 0 {
            self.hidden = true
        }
        else {
            initPreviewPattern(numImgs)
            
            for preImg in m_preImgs {
                preImg.hidden = true
            }
            
            let fullSize = self.frame.height
            let blkSize = (self.frame.height - PostPreViewGap) / 2
            let step = blkSize + PostPreViewGap
            
            for var i=0; i<numImgs; i++ {
                let layout = m_pattern[i]
                let size = (layout.scale == 1 ? blkSize : fullSize)
                m_preImgs[i].hidden = false
                m_preImgs[i].image = post.getPreview(i)
                m_preImgs[i].frame = CGRectMake(CGFloat(layout.xNumBlk)*step, CGFloat(layout.yNumBlk)*step, size, size)
            }
        }
    }
    
    func getFullImg(idx:Int) {
        //http.getFile((m_post?.m_imgUrls[idx])!,
        //    success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                //let data = response as! NSData
                //cell.m_preview.image = UIImage(data: data)
        //    },
        //    fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        //        print("请求失败")
        //    }
        //)
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
