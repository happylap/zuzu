//
//  MyNoteViewController.swift
//  Zuzu
//
//  Created by eechih on 2015/11/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//


import UIKit

class MyNoteViewController: UIViewController, UITextFieldDelegate {
    
    var noteList: [String] = []
    
    var houseItem: House?
    
    @IBOutlet weak var noteItemForCreate: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addNoteItem(sender: UIButton) {
        NSLog("%@ addNoteItem", self)
        
        if self.noteItemForCreate.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            noteList.append(self.noteItemForCreate.text!)
            if let house = self.houseItem {
                NoteDao.sharedInstance.addNote(house.id, noteDesc: self.noteItemForCreate.text!)
                houseItem = HouseDao.sharedInstance.getHouseById(house.id)
            }
            self.noteItemForCreate.text = ""
            self.view.endEditing(true)
            
            self.tableView.reloadData()
        }
    }
    
    @IBAction func returnMainTable(sender: UIButton) {
        NSLog("%@ returnMainTable", self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("%@ viewDidLoad", self)
        noteItemForCreate.delegate = self
        
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    var kbHeight: CGFloat!
    
    func keyboardWillShow(notification: NSNotification) {
        NSLog("%@ keyboardWillShow", self)
        
//        if let userInfo = notification.userInfo {
//            if let keyboardSize =  (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                kbHeight = keyboardSize.height
//                self.animateTextField(true)
//            }
//        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        NSLog("%@ keyboardWillHide", self)
//        self.animateTextField(false)
    }
    
    func animateTextField(up: Bool) {
//        let movement = (up ? -kbHeight : kbHeight)
//        
//        UIView.animateWithDuration(0.3, animations: {
//            self.view.frame = CGRectOffset(self.view.frame, 0, movement)
//        })
    }
}

extension MyNoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.noteList.count
//        return self.houseItem?.notes.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        // Configure the cell...
        cell.textLabel?.text = self.noteList[indexPath.row]
//        if let note = self.houseItem?.notes[indexPath.row] as? Note {
//            cell.textLabel?.text = note.desc
//        }
        
        return cell
    }
    
    // MARK: - Table Edit Mode
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let _: String = self.noteList[indexPath.row] as String {
                self.noteList.removeAtIndex(indexPath.row)
                self.tableView.reloadData()
            }
        }
    }
}