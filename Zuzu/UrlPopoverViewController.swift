//
//  UrlPopoverViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

protocol UrlPopoverViewControllerDelegate {
    func onUrlCopiedDone(status:Bool)
}

class UrlPopoverViewController: UIViewController {
    
    @IBOutlet weak var compactView: UIView!
    var urlLabelText:String?
    
    @IBOutlet weak var copyUrlButton: UIButton!
    @IBOutlet weak var urlLabel: UILabel!
    
    var delegate:UrlPopoverViewControllerDelegate?
    
    // MARK: - Private Utils
    private func onContentSizeChanged(size: CGSize) {
        self.preferredContentSize = size
    }
    
    func onCopybuttonTouched(sender:UIButton) {
        if let text = urlLabel.text {
            UIPasteboard.generalPasteboard().string = text
            delegate?.onUrlCopiedDone(true)
        } else {
            delegate?.onUrlCopiedDone(false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        copyUrlButton.addTarget(self, action: "onCopybuttonTouched:", forControlEvents: .TouchDown)
        self.urlLabel.text = urlLabelText
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = view.window?.bounds.width ?? compactView.bounds.size.width
        let newSize = CGSize(width: width, height: compactView.bounds.size.height)
        onContentSizeChanged(newSize)
    }
    
}
