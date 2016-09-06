//
//  MyNoteViewCell.swift
//  Zuzu
//
//  Created by eechih on 12/2/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//
import UIKit
import MarqueeLabel

class MyNoteViewCell: UITableViewCell {

    @IBOutlet weak var noteTitle: UILabel! {
        didSet {
            let label: MarqueeLabel =  noteTitle as! MarqueeLabel
            label.userInteractionEnabled = true
            label.trailingBuffer = 60
            label.rate = 60 //pixels/sec
            label.fadeLength = 6
            label.animationDelay = 1 //Sec
            label.marqueeType = .MLContinuous
        }
    }

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
