//
//  PromotionService.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import AwesomeCache
import SafariServices

private let Log = Logger.defaultLogger

public class PromotionService: NSObject {

    // MARK: - Private Members

    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: PromotionService {
        struct Singleton {
            static let instance = PromotionService()
        }

        return Singleton.instance
    }
    private let rentDiscountImage = UIImageView(image: UIImage(named: "rent-discount")?.imageWithRenderingMode(.AlwaysTemplate))

    private var experimentData: ExperimentData?

    private var parentViewController: UIViewController?

    private var popupController: CNPPopupController = CNPPopupController()

    private var isButtonClicked: Bool = false

    /// Cache constants
    private let cacheName = "experimentCache"
    private let cacheKey = "displayRentDiscount"
    private let cacheTime: Double = 24 * 60 * 60 //24 hours

    /// Delay display delay constants
    private let maxDelayDays = 365 // A year later
    private let delayStep = 2 // double the delay


    // MARK: - Private API
    private func setNextDisplayDate(delayDays: Int) {

        UserDefaultsUtils.setRentDiscountDisplayDelayFactor(delayDays)

        let nextDate = NSDate().add(days: delayDays)
        UserDefaultsUtils.setNextRentDiscountDisplayDate(nextDate)

        Log.debug("Delay for \(delayDays) days until \(nextDate)")
    }

    private func allowDisplayRentDiscount() -> Bool {

        if let nextDate = UserDefaultsUtils.getNextRentDiscountDisplayDate() {

            Log.debug("Should not display until \(nextDate)")

            if(nextDate.timeIntervalSinceNow > 0) {
                return false // Not yet
            } else {
                return true
            }

        } else {
            return true
        }

    }

    private func setRentDiscountDisplayed(isDisplay: Bool) {

        ///Try to cache the house detail response
        do {
            let cache = try Cache<NSData>(name: self.cacheName)
            let cachedData = NSKeyedArchiver.archivedDataWithRootObject(isDisplay)
            cache.setObject(cachedData, forKey: cacheKey, expires: CacheExpiry.Seconds(self.cacheTime))

        } catch _ {
            Log.debug("Something went wrong with the cache")
        }

    }

    private func isRentDiscountDisplayed() -> Bool {

        do {
            let cache = try Cache<NSData>(name: cacheName)

            ///Return cached data if there is cached data
            if let cachedData = cache.objectForKey(cacheKey),
                let displayed = NSKeyedUnarchiver.unarchiveObjectWithData(cachedData) as? Bool {

                Log.debug("Hit Cache for: \(cacheKey), displayed: \(displayed)")

                return displayed
            }

            return false

        } catch _ {
            Log.debug("Something went wrong with the cache")

            return false
        }
    }

    // MARK: - Public API

    internal func tryShowPopupFromViewController(viewController: UIViewController, popupStyle: CNPPopupStyle, data: ExperimentData) {

        /// Check if the experiment can be displayed for the current date
        if(!self.allowDisplayRentDiscount()) {
            return
        }

        /// Check if the experiment is shown within 24 hours
        if(self.isRentDiscountDisplayed()) {
            return
        }

        self.showPopupFromViewController(viewController, popupStyle: popupStyle, data: data)

    }

    internal func showPopupFromViewController(viewController: UIViewController, popupStyle: CNPPopupStyle, data: ExperimentData) {

        self.isButtonClicked = false

        parentViewController = viewController

        experimentData = data

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center

        let titleStyle = NSAttributedString(string: data.title ?? "好房客募集中！", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(20), NSForegroundColorAttributeName: UIColor.darkGrayColor(), NSParagraphStyleAttributeName: paragraphStyle])

        let subtitleStyle = NSAttributedString(string: data.subtitle ?? "豬豬即將推出好房客租金優惠平台\n經過身份認證的房客租到房子，不但不用付仲介費，還可以得到首月房租折扣，就是這麼簡單！", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.grayColor(), NSParagraphStyleAttributeName: paragraphStyle])

        let okButton = CNPPopupButton(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        okButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        okButton.titleLabel?.font = UIFont.boldSystemFontOfSize(18)
        okButton.setTitle("我有興趣", forState: UIControlState.Normal)

        okButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6)
        okButton.layer.cornerRadius = 4
        okButton.selectionHandler = { (button) -> Void in
            self.popupController.dismissPopupControllerAnimated(true)
            Log.debug("Button click: \(button.titleLabel?.text)")

            if let landingPage = data.url {

                if #available(iOS 9.0, *) {
                    let svc = SFSafariViewController(URL: NSURL(string: landingPage)!)
                    viewController.presentViewController(svc, animated: true, completion: nil)

                    ///GA Tracker: Campaign Clicked
                    viewController.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                              action: GAConst.Action.Campaign.RentDiscountReach, label: data.title)
                } else {
                    // Fallback on earlier versions

                    let storyboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
                    let browserViewController = storyboard.instantiateViewControllerWithIdentifier("browserView") as? BrowserViewController

                    if let browserViewController = browserViewController {
                        browserViewController.enableToolBar = false
                        browserViewController.sourceLink = landingPage
                        browserViewController.viewTitle = "優質房客大募集"

                        viewController.navigationController?.pushViewController(browserViewController, animated: true)

                        ///GA Tracker: Campaign Clicked
                        viewController.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                                  action: GAConst.Action.Campaign.RentDiscountReach, label: data.title)
                    }
                }
            }

            self.setNextDisplayDate(self.maxDelayDays)

            ///GA Tracker: Campaign Clicked
            viewController.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                      action: GAConst.Action.Campaign.RentDiscountClick, label: data.title)

            self.isButtonClicked = true
        }


        let laterButton = CNPPopupButton.init(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        laterButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        laterButton.titleLabel?.font = UIFont.systemFontOfSize(18)
        laterButton.setTitle("下次再說", forState: UIControlState.Normal)

        laterButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6)

        laterButton.layer.cornerRadius = 4
        laterButton.selectionHandler = { (button) -> Void in
            self.popupController.dismissPopupControllerAnimated(true)
            Log.debug("Button click: \(button.titleLabel?.text)")


            var delayFactor: Int = 1

            if let currentDelayFactor = UserDefaultsUtils.getRentDiscountDisplayDelayFactor() {

                delayFactor = (currentDelayFactor * self.delayStep) % self.maxDelayDays

            }

            self.setNextDisplayDate(delayFactor)

            ///GA Tracker: Campaign Clicked
            viewController.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                             action: GAConst.Action.Campaign.RentDiscountLater, label: data.title)
            self.isButtonClicked = true
        }

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = titleStyle
        titleLabel.autoScaleFontSize = true

        rentDiscountImage.tintColor = UIColor.darkGrayColor()

        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.attributedText = subtitleStyle
        subtitleLabel.autoScaleFontSize = true

        self.popupController = CNPPopupController(contents:[titleLabel, rentDiscountImage, subtitleLabel, okButton, laterButton])
        self.popupController.theme = CNPPopupTheme.defaultTheme()
        self.popupController.theme.popupStyle = popupStyle
        self.popupController.theme.maskType = .Dimmed
        self.popupController.delegate = self
        self.popupController.presentPopupControllerAnimated(true)

        /// Display Control
        self.setRentDiscountDisplayed(true)
    }


}

// MARK: - CNPPopupControllerDelegate
extension PromotionService : CNPPopupControllerDelegate {

    public func popupControllerWillDismiss(controller: CNPPopupController!) {
        controller
        Log.enter()

        /// The dialog is closed by touching background
        if(!self.isButtonClicked) {

            var delayFactor: Int = 1

            if let currentDelayFactor = UserDefaultsUtils.getRentDiscountDisplayDelayFactor() {

                delayFactor = (currentDelayFactor * self.delayStep) % self.maxDelayDays

            }

            self.setNextDisplayDate(delayFactor)

            ///GA Tracker: Campaign Clicked
            parentViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                             action: GAConst.Action.Campaign.RentDiscountLater, label: experimentData?.title)

        }
    }

    public func popupControllerDidPresent(controller: CNPPopupController) {
        Log.enter()
    }

}
