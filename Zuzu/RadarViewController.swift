//
//  RadarViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import AWSCore
import AWSS3

class RadarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

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
                NSLog("Error: %@", task.error!)
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
