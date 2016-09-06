//
//  WalkthroughMasterViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import BWWalkthrough
import SCLAlertView

class WalkthroughMasterViewController: BWWalkthroughViewController {

    private var popupController: CNPPopupController = CNPPopupController()

    @IBOutlet weak var closeWalkthroughButton: UIButton! {

        didSet {

            closeWalkthroughButton.layer.borderWidth = 1
            closeWalkthroughButton.layer.borderColor =
                UIColor.colorWithRGB(0xFFFFFF, alpha: 1).CGColor
            closeWalkthroughButton.tintColor =
                UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            closeWalkthroughButton
                .setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: UIControlState.Normal)
            closeWalkthroughButton
                .setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: UIControlState.Selected)

        }
    }

    //TODO: Do not use data from tag manager
    private func displayServiceAgreement() {

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleStyle.alignment = NSTextAlignment.Center

        let titleAttribute = NSAttributedString(string: "「豬豬快租」服務使用條款", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.darkGrayColor(), NSParagraphStyleAttributeName: titleStyle])

        let agreementStr =
            "1.「豬豬快租」為一台灣租屋資訊搜尋引擎 App，僅針對網路公開租屋資料做蒐集、索引，以便於房客更快速地一次搜尋租屋物件。\n\n" +
                "2.「豬豬快租」和各物件來源網站並無任何合作關係，所有物件資料並非各租屋網站給予或售予「豬豬快租」。\n\n" +
                "3.「豬豬快租」對 App 內展示的資料，並不具任何控制權或所有權，因此也不為租屋物件資料的正確性負任何責任。任何因物件資料錯誤所造成的損害皆與本公司無關。\n\n" +
        "4. 若物件資料內容涉及違法事項，「豬豬快租」收到用戶舉報後會盡力將物件下架，減少對使用者的影響，但是相關的法律責任概由資料原始張貼人負責。"

        let agreementCheckStr = "點選下方「我接受」按鈕表示您已經完全理解並接受上述條款。" +
        "若不接受本服務條款，請勿使用本 App，謝謝您。"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Left

        let subtitleAttribute = NSAttributedString(string: agreementStr, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.grayColor(), NSParagraphStyleAttributeName: paragraphStyle])

        let agreeAttribute = NSAttributedString(string: agreementCheckStr, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.colorWithRGB(0x1CD4C6), NSParagraphStyleAttributeName: titleStyle])

        let okButton = CNPPopupButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        okButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        okButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
        okButton.titleLabel?.autoScaleFontSize = true
        okButton.setTitle("我接受", forState: UIControlState.Normal)

        okButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6)
        okButton.layer.cornerRadius = 4
        okButton.autoScaleRadious = true

        okButton.selectionHandler = { (button) -> Void in
            self.popupController.dismissPopupControllerAnimated(true)
        }

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = titleAttribute
        titleLabel.autoScaleFontSize = true

        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.attributedText = subtitleAttribute
        subtitleLabel.autoScaleFontSize = true

        let agreeLabel = UILabel()
        agreeLabel.numberOfLines = 0
        agreeLabel.attributedText = agreeAttribute
        agreeLabel.autoScaleFontSize = true

        self.popupController = CNPPopupController(contents:[titleLabel, subtitleLabel, agreeLabel, okButton])
        self.popupController.theme = CNPPopupTheme.defaultTheme()
        self.popupController.theme.popupStyle = CNPPopupStyle.Centered
        self.popupController.theme.maskType = .Dimmed
        self.popupController.delegate = self
        self.popupController.presentPopupControllerAnimated(true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        self.runOnMainThreadAfter(1.0) {
            self.displayServiceAgreement()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension WalkthroughMasterViewController : CNPPopupControllerDelegate {

    func popupController(controller: CNPPopupController, dismissWithButtonTitle title: NSString) {
        print("Dismissed with button title \(title)")
    }

    func popupControllerDidPresent(controller: CNPPopupController) {
        print("Popup controller presented")
    }

}
