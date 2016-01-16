//
//  DetailViewController.swift
//  inappragedemo
//
//  Created by Ray Fix on 5/1/15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    var image: UIImage? {
        didSet {
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    @IBOutlet weak var imageView: UIImageView?
    
    func configureView() {
        imageView?.image = image
    }
    
}

