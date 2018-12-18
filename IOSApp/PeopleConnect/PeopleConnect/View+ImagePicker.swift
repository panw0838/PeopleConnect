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
    @IBOutlet weak var m_mark: UILabel!
    var m_asset:PHAsset? = nil
    var m_order:Int = 0
}

class MulImgPicker: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var m_maxCount = 8
    var m_imgMgr = PHCachingImageManager()
    var m_imgs:Array<PHAsset>? = nil
    var m_selected = Array<PHAsset>()
    
    @IBOutlet weak var m_imgTable: UICollectionView!

    override func viewDidLoad() {
        fetchAssets()
        m_imgTable.allowsMultipleSelection = true
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
        
        m_imgs = items.copy() as? Array<PHAsset>
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_imgs?.count)!
    }
        
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: indexPath) as! ImgCell
        cell.m_asset = m_imgs![indexPath.row]
        cell.m_mark.hidden = !cell.selected
        
        if m_selected.contains(cell.m_asset!) {
            let idx = m_selected.indexOf(cell.m_asset!)
            cell.m_mark.text = String(idx!+1)
        }

        m_imgMgr.requestImageForAsset(cell.m_asset!, targetSize: CGSizeMake(40, 40), contentMode: .AspectFill, options: nil, resultHandler: {
            (result:UIImage?, info:[NSObject:AnyObject]?)->Void in
                cell.m_img.image = result
            })
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        if cell.selected || m_selected.count == m_maxCount {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        
        cell.m_mark.hidden = true
        
        let idx = m_selected.indexOf(cell.m_asset!)
        m_selected.removeAtIndex(idx!)
        for var i=idx!; i<m_selected.count; i++ {
            let k = m_imgs?.indexOf(m_selected[i])
            let c = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: k!, inSection: 0)) as? ImgCell
            if c != nil {
                c!.m_mark.text = String(i+1)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        cell.m_mark.hidden = false
        m_selected.append(cell.m_asset!)
        cell.m_mark.text = String(m_selected.count)
    }
}