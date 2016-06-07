//
//  MyNoteViewController.swift
//  Zuzu
//
//  Created by eechih on 2015/11/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//


import UIKit
import CoreData

private let Log = Logger.defaultLogger

class MyNoteViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let cellReuseIdentifier = "NoteCell"
    
    struct TableConst {
        static let sectionNum:Int = 1
    }
    
    var collectionHouseItem: CollectionHouseItem?
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Note")
        
        // Add Predicates
        if let house = self.collectionHouseItem {
            let findByIdPredicate = NSPredicate(format: "houseId == %@", house.id)
            fetchRequest.predicate = findByIdPredicate
        }
        
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
//    private func addNote(title: String) {
//        if let house = self.collectionHouseItem {
//            NoteService.sharedInstance.addNote(house.id, title: title)
//        }
//    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noteItemForCreate: UITextField!
    
    // MARK: Actions
    @IBAction func addNoteItem(sender: UIButton) {
        Log.debug("\(self) addNoteItem")
        if self.noteItemForCreate.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            //self.addNote(self.noteItemForCreate.text!)
            if let house = self.collectionHouseItem {
                NoteService.sharedInstance.addNote(house.id, title: self.noteItemForCreate.text!)
            }
            self.noteItemForCreate.text = ""
            self.view.endEditing(true)
        }
    }
    
    @IBAction func returnMainTable(sender: UIButton) {
        Log.debug("\(self) returnMainTable")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug("\(self) viewDidLoad")
        noteItemForCreate.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            Log.debug("\(fetchError), \(fetchError.userInfo)")
        }
        
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // self.tableView.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        
        // self.tableView.tableFooterView?.backgroundColor = UIColor.clearColor()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyNoteViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyNoteViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

extension MyNoteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        Log.debug("\(self) keyboardWillShow")
    }
    
    func keyboardWillHide(notification: NSNotification) {
        Log.debug("\(self) keyboardWillHide")
    }
}

extension MyNoteViewController {
    
    // MARK: - Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! MyNoteViewCell
        
        Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")
        
        if let note = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Note {
            cell.noteItem = note
        }
        
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    
    // MARK: - Table Edit Mode
    

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        let deleteButton = UITableViewRowAction(style: .Default, title: "", handler: { (action, indexPath) in
            Log.debug("Delete pressed!")
            self.tableView(tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: indexPath)
        })
        
        deleteButton.backgroundColor = UIColor(patternImage: UIImage(named: "delete_icon_small")!)
        

        
        //deleteButton.backgroundColor = UIColor(patternImage: UIImage(named: "")).colorWithRGB(0x1cd4c6)
        
        return [deleteButton]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let note = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Note {
                NoteService.sharedInstance.deleteNote(note.id)
            }
        }
    }
    

    
    // MARK: -
    // MARK: Fetched Results Controller Delegate Methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        Log.debug("\(self) didChangeObject: \(type.rawValue)")
        
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as? MyNoteViewCell {
                if let note: Note = self.fetchedResultsController.objectAtIndexPath(indexPath!) as? Note {
                    cell.noteItem = note
                }
            } else {
                assert(false, "MyNote Cell at row: \(indexPath?.row) is nil")
            }
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}