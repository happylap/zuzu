//
//  MyNoteViewCell.swift
//  Zuzu
//
//  Created by eechih on 12/2/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//
import UIKit

class MyNoteViewCell: UITableViewCell {

    @IBOutlet weak var noteTitle: UILabel!
    
    var noteItem: Note? {
        didSet {
            updateUI()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset any existing information
        self.noteTitle.text = nil
        
    }
    
    func updateUI() {
        if let note = noteItem {
            self.noteTitle.text = note.title
        }
    }
    
}
    