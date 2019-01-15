//
//  View+SearchGroup.swift
//  PeopleConnect
//
//  Created by apple on 19/1/14.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class SearchGroupView:UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var m_editor: UITextField!
    @IBOutlet weak var m_resultsTable: UITableView!
    
    static var results = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifier = NSNotificationCenter.defaultCenter()
        notifier.addObserver(self, selector: Selector("inputChanged"), name: UITextFieldTextDidChangeNotification, object: nil)
    }
    
    func inputChanged() {
        let keyword = m_editor.text
        if keyword?.characters.count > 0 {
            httpSearchGroup(keyword!,
                passed: {()->Void in
                    self.m_resultsTable.reloadData()
                },
                failed: {(err:String?)->Void in
                    self.m_resultsTable.reloadData()
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchGroupView.results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SearchCell")
        cell?.textLabel?.text = SearchGroupView.results[indexPath.row]
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        let alert = UIAlertController(title: "添加大学", message: "你已选择" + cell!.textLabel!.text! + "，点击确定加入", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                gLoadingView.startLoading()
                httpAddGroup(cell!.textLabel!.text!,
                    passed: {()->Void in
                        gLoadingView.stopLoading()
                        self.navigationController?.popViewControllerAnimated(true)
                    },
                    failed: {(err:String?)->Void in
                        gLoadingView.stopLoading()
                        self.navigationController?.popViewControllerAnimated(true)
                    })
        })
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
