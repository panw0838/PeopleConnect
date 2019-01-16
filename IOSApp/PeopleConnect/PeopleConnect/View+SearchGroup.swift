//
//  View+SearchGroup.swift
//  PeopleConnect
//
//  Created by apple on 19/1/14.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class SearchGroupView:UIViewController,
    UITextFieldDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIPickerViewDataSource,
    UIPickerViewDelegate {
    
    @IBOutlet weak var m_editor: UITextField!
    @IBOutlet weak var m_resultsTable: UITableView!
    @IBOutlet weak var m_yearPicker: UIPickerView!
    @IBOutlet weak var m_doneBtn: UIBarButtonItem!

    static var results = Array<String>()
    var m_year = getCurYear()
    
    var m_preController:PostsView?
    
    @IBAction func joinUniv() {
        let alert = UIAlertController(title: m_editor.text!, message: String(m_year)+"年入学", preferredStyle: .Alert)
        let noAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: .Default,
            handler: { action in
                gLoadingView.startLoading()
                httpAddGroup(self.m_editor.text!, year:self.m_year,
                    passed: {()->Void in
                        gLoadingView.stopLoading()
                        self.navigationController?.popViewControllerAnimated(true)
                        self.m_preController?.NewGroupAdded()
                    },
                    failed: {(err:String?)->Void in
                        gLoadingView.stopLoading()
                })
        })
        alert.addAction(noAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifier = NSNotificationCenter.defaultCenter()
        notifier.addObserver(self, selector: Selector("inputChanged"), name: UITextFieldTextDidChangeNotification, object: nil)
        m_doneBtn.enabled = false
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let curYear = getCurYear()
        return curYear - 1900 + 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let curYear = getCurYear()
        return String(curYear - row) + "年入学"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let curYear = getCurYear()
        m_year = curYear - row
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        m_editor.endEditing(true)
        return true
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
        m_editor.text = cell?.textLabel?.text
        m_editor.endEditing(true)
        m_doneBtn.enabled = true
    }
}
