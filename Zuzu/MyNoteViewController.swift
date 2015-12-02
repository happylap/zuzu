//
//  MyNoteViewController.swift
//  Zuzu
//
//  Created by eechih on 2015/11/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//


import UIKit
import CoreData

class MyNoteViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let cellReuseIdentifier = "NoteCell"
    
    var houseItem: House?
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Note")
        
        // Add Predicates
        if let house = self.houseItem {
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
    
    private func addNote(title: String) {
        if let house = self.houseItem {
            let context = CoreDataManager.shared.managedObjectContext
            
            if let model = NSEntityDescription.entityForName(EntityTypes.Note.rawValue, inManagedObjectContext: context) {
                let note = Note(entity: model, insertIntoManagedObjectContext: context)
                note.title = title
                note.desc = title
                note.createDate = NSDate()
                note.houseId = house.id
                CoreDataManager.shared.save()
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noteItemForCreate: UITextField!
    
    // MARK: Actions
    @IBAction func addNoteItem(sender: UIButton) {
        NSLog("%@ addNoteItem", self)
        if self.noteItemForCreate.text?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            self.addNote(self.noteItemForCreate.text!)
            self.noteItemForCreate.text = ""
            self.view.endEditing(true)
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
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // self.tableView.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        
        // self.tableView.tableFooterView?.backgroundColor = UIColor.clearColor()
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
    
}

extension MyNoteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {
        NSLog("%@ keyboardWillShow", self)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        NSLog("%@ keyboardWillHide", self)
    }
}

extension MyNoteViewController {
    
    // MARK: - Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
        //return fetchedResultsController.sections!.count
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.noteList.count
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! MyNoteViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        if let note = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Note {
            //cell.textLabel?.text = note.title
            
            cell.noteItem = note
        }
        
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    
    // MARK: - Table Edit Mode
    

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        let deleteButton = UITableViewRowAction(style: .Default, title: "", handler: { (action, indexPath) in
            print("Delete pressed!")
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
                CoreDataManager.shared.delete(note.objectID)
                CoreDataManager.shared.save()
            }
        }
    }
    

    
    // MARK: -
    // MARK: Fetched Results Controller Delegate Methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        NSLog("%@ didChangeObject: \(type.rawValue)", self)
        
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! MyNoteViewCell
            if let note: Note = self.fetchedResultsController.objectAtIndexPath(indexPath!) as? Note {
                //cell.textLabel?.text = note.title
                cell.noteItem = note
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