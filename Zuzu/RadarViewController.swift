//
//  RadarViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import AWSCore
import AWSS3
import FLAnimatedImage
import GoogleMobileAds
import FBAudienceNetwork

private let Log = Logger.defaultLogger

class RadarViewController: UIViewController {
    
    private let testDevice = ["a78e7dfcf98d255d2c1d107bb5e96449"]
    
    let bannerView = GADBannerView()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let request = GADRequest()
        request.testDevices = self.testDevice
        bannerView.loadRequest(request)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* GIF Animation Sample */
        //        let image: FLAnimatedImage =
        //        FLAnimatedImage(animatedGIFData: NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("ic_loginLoading", ofType: "gif")!))
        //
        //        let imageView: FLAnimatedImageView = FLAnimatedImageView()
        //        imageView.animatedImage = image
        //        imageView.frame = CGRectMake(100.0, 100.0, 100.0, 100.0)
        //        self.view!.addSubview(imageView)
        
        /* FB AD Sample */
        //        let adView: FBAdView =
        //        FBAdView(placementID:"1039275546115316_1054997774543093", adSize:kFBAdSizeHeight90Banner, rootViewController:self)
        //        FBAdSettings.addTestDevice("0d5e4441357c49679cace1707412a6b516d3bb36")
        //        adView.loadAd()
        //        self.view.addSubview(adView)
        
        /* ADMOB AD Sample */
        //Test adUnit
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        //Real adUnit, DONT'T USE THIS YET!
        //bannerView.adUnitID = "ca-app-pub-7083975197863528/3785388890"
        
        bannerView.frame = CGRectMake(100.0, 100.0, 320, 100)
        bannerView.adSize = kGADAdSizeBanner//kGADAdSizeLargeBanner
        bannerView.rootViewController = self
        bannerView.delegate = self
        
        let request = GADRequest()
        request.testDevices = self.testDevice
        bannerView.loadRequest(request)
        self.view!.addSubview(bannerView)
        
        /* Cognito S3 Sample */
        /// 1.Initialize the Amazon Cognito credentials provider
        /*let poolId = "ap-northeast-1:7e09fc17-5f4b-49d9-bb50-5ca5a9e34b8a"
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.APNortheast1,
        identityPoolId: poolId)
        
        // Config the default serivce. Make sure the region is where your S3 bucket created
        // In out case, APSoutheast1
        let configuration = AWSServiceConfiguration(region:.APSoutheast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        /// 2. Load image from S3
        
        let transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        let downloadingFilePath: String = NSTemporaryDirectory().stringByAppendingString("/downloaded-myImage.jpg")
        let downloadingFileURL: NSURL = NSURL.fileURLWithPath(downloadingFilePath)
        
        // Construct the download request.
        let downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        
        downloadRequest.bucket = "zuzu.mycollection"
        downloadRequest.key = "test.jpg"
        downloadRequest.downloadingFileURL = downloadingFileURL
        
        
        
        /// 3. Start downloading the file.
        transferManager.download(downloadRequest).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {(task: AWSTask) -> AnyObject? in
        
        if( task.result != nil) {
        let _: AWSS3TransferManagerDownloadOutput = task.result as! AWSS3TransferManagerDownloadOutput
        
        //File downloaded successfully. Add the image to the view
        let imgView = UIImageView(image: UIImage(contentsOfFile: downloadingFilePath))
        
        self.view.addSubview(imgView)
        } else {
        Log.debug("Error: %@", task.error!)
        }
        return nil
        })
        */
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

// MARK: - GADBannerViewDelegate
extension RadarViewController: GADBannerViewDelegate {
    
    internal func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Log.enter()
        Log.debug("Banner adapter class name: \(bannerView.adNetworkClassName)")
    }
    internal func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Log.enter()
    }
    internal func adViewWillPresentScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewDidDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        Log.enter()
    }
}
