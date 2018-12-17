//
//  View+ImagePicker.swift
//  PeopleConnect
//
//  Created by apple on 18/12/5.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class ImgCell:UICollectionViewCell {
    @IBOutlet weak var m_img: UIImageView!
    @IBOutlet weak var m_select: UIImageView!
    var m_asset:PHAsset? = nil
}

class MulImgPicker: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var m_selectImgs = Set<PHAsset>()
    var m_maxCount = 8
    var m_imgMgr = PHCachingImageManager()
    var m_imgs:Array<AnyObject>? = nil
    
    override func viewDidLoad() {
        fetchAssets()
    }
    
    func searchAsset(collections:PHFetchResult, items:NSMutableArray, options:PHFetchOptions) {
        for var i=0; i<collections.count; i++ {
            let obj = collections.objectAtIndex(i)
            if obj.isKindOfClass(PHAssetCollection) {
                let asset = obj as! PHAssetCollection
                let result = PHAsset.fetchAssetsInAssetCollection(asset, options: options)
                if result.count > 0 {
                    let range = NSMakeRange(0, result.count)
                    items.addObjectsFromArray(result.objectsAtIndexes(NSIndexSet(indexesInRange: range)))
                }
            }
            else if obj.isKindOfClass(PHCollectionList) {
                let list = obj as! PHCollectionList
                let result = PHCollectionList.fetchCollectionsInCollectionList(list, options: nil)
                searchAsset(result, items: items, options: options)
            }
        }
    }

    func fetchAssets() {
        let items = NSMutableArray()

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let topList = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(nil)
        searchAsset(topList, items: items, options: options)
        
        let albums = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
        
        for var i=0; i<albums.count; i++ {
            let collection = albums.objectAtIndex(i) as! PHAssetCollection
            let result = PHAsset.fetchAssetsInAssetCollection(collection, options: options)
            if result.count > 0 {
                if collection.assetCollectionSubtype == .SmartAlbumUserLibrary {
                    let range = NSMakeRange(0, result.count)
                    items.addObjectsFromArray(result.objectsAtIndexes(NSIndexSet(indexesInRange: range)))
                }
                else {
                    let range = NSMakeRange(0, result.count)
                    items.addObjectsFromArray(result.objectsAtIndexes(NSIndexSet(indexesInRange: range)))
                }
            }
        }
        
        m_imgs = items.copy() as? Array<AnyObject>
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_imgs?.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: indexPath) as! ImgCell
        cell.m_asset = m_imgs![indexPath.row] as? PHAsset
        cell.m_select.hidden = !cell.selected
        m_imgMgr.requestImageForAsset(cell.m_asset!, targetSize: CGSizeMake(40, 40), contentMode: .AspectFill, options: nil, resultHandler: {
            (result:UIImage?, info:[NSObject:AnyObject]?)->Void in
                cell.m_img.image = result
            })
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        if cell.selected || m_selectImgs.count == m_maxCount {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        cell.m_select.hidden = true
        m_selectImgs.remove(cell.m_asset!)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        cell.m_select.hidden = false
        m_selectImgs.insert(cell.m_asset!)
    }
}