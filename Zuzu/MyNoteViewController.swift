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

class MyNoteViewController: UIViewController {
    
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
    
    // MARK: Private Utils
    private func saveNoteItem(title: String) {
        
        if let house = self.collectionHouseItem {
            NoteService.sharedInstance.addNote(house.id, title: self.noteItemForCreate.text!)
        }
        
    }
    
    /** Do not use for now
     private func imageWithBgColor(image: UIImage, color: UIColor) -> UIImage {
     
     let rect:CGRect = CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0)
     UIGraphicsBeginImageContext(rect.size)
     let context:CGContextRef? = UIGraphicsGetCurrentContext()
     
     CGContextSetFillColorWithColor(context, color.CGColor)
     CGContextFillRect(context, rect)
     
     CGContextTranslateCTM(context, rect.origin.x, rect.origin.y)
     CGContextTranslateCTM(context, 0, rect.size.height)
     CGContextScaleCTM(context, 1.0, -1.0)
     CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y)
     CGContextDrawImage(context, rect, image.CGImage)
     
     let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
     UIGraphicsEndImageContext()
     
     return image
     
     }
     **/
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noteItemForCreate: UITextField!
    
    // MARK: Actions
    @IBAction func addNoteItem(sender: UIButton) {
        Log.enter()
        
        if let noteItemText = self.noteItemForCreate.text
            where noteItemText.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            
            saveNoteItem(noteItemText)
            
            self.noteItemForCreate.text = nil
            self.view.endEditing(true)
        }
    }
    
    @IBAction func returnMainTable(sender: UIButton) {
        Log.enter()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Close keyboard when touching on other area
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if (noteItemForCreate.isFirstResponder() && touch.view != noteItemForCreate) {
                noteItemForCreate.resignFirstResponder()
            }
        }
        super.touchesBegan(touches, withEvent:event)
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.enter()
        
        noteItemForCreate.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            Log.debug("\(fetchError), \(fetchError.userInfo)")
        }
        
        // Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
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

// MARK: - UITextFieldDelegate
extension MyNoteViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if let noteItemText = textField.text
            where noteItemText.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            
            saveNoteItem(noteItemText)
            
            textField.text = nil
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        Log.enter()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        Log.enter()
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MyNoteViewController: NSFetchedResultsControllerDelegate {
    
    // Table View Data Source
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
    
    // Table Edit Mode
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        let deleteButton = UITableViewRowAction(style: .Default, title: "  ", handler: { (action, indexPath) in
            Log.debug("Delete pressed!")
            self.tableView(tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: indexPath)
        })
        
        deleteButton.backgroundColor = UIColor(patternImage: UIImage(named: "delete_icon_small")!)
        
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
    
    // Fetched Results Controller Delegate Methods
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