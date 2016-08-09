# Uncomment this line to define a global platform for your project
link_with 'Zuzu', 'ZuzuTests'  

platform :ios, '8.0'
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end

target 'Zuzu' do
pod 'Alamofire', '2.0.2'
pod 'AlamofireImage', '1.1.2'
pod 'AWSCore', '2.3.5'
pod 'AWSS3', '2.3.5'
pod 'AWSCognito', '2.3.5'
pod 'AWSSNS', '2.3.5'
pod 'AwesomeCache', '2.0'
pod 'Dollar', '4.0.1'
pod 'Device', '0.0.4'
pod 'FBSDKCoreKit', '4.10.1'
pod 'FBSDKLoginKit', '4.10.1'
pod 'FBSDKShareKit', '4.10.1'
pod 'FLAnimatedImage', '1.0.10'
pod 'Fabric', '1.6.4'
pod 'mopub-ios-sdk', '4.3.0'
pod 'GoogleMaps', '1.10.5'
pod 'Google/Analytics', '2.0.4'
pod 'Google/SignIn', '2.0.4'
pod 'Google/AdMob', '2.0.4'
pod 'GoogleIDFASupport', '3.14.0'
pod 'GoogleTagManager', '3.15.0'
pod 'MWPhotoBrowser', '2.1.1'
pod 'MarqueeLabel', '2.3.5'
pod 'MBProgressHUD', '0.9.1'
pod 'NSLogger', '1.5.1'
pod 'ObjectMapper', '1.1.0'
pod 'SwiftDate', '2.0.2'
pod 'SwiftyJSON', '2.3.0'
pod 'SCLAlertView', '0.4.3'
pod 'SDWebImage', '3.7.3'
pod 'KeychainAccess', '2.3.5'
pod 'XCGLogger', '3.2'
pod 'Charts', '2.2.3'
pod 'SwiftValidator', '3.0.3'
pod 'BWWalkthrough', '1.1.0'
pod 'VMFiveAdNetwork', '2.1.4'
pod 'BGTableViewRowActionWithImage'
pod 'CNPPopupController', '0.3.1'
pod 'JKNotificationPanel', '0.2.0'

# The following libs are disabled for now to save some App size
#pod 'CWStatusBarNotification', '2.3.1'
#pod 'UICKeyChainStore', '2.0.7'
#pod 'SwiftyStateMachine', '0.3.0'
end

target 'ZuzuTests' do

end

target 'ZuzuUITests' do

end

