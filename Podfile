source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.2'
inhibit_all_warnings!
use_frameworks!

pod 'Fabric'
pod 'Crashlytics'
pod 'DTCoreText'
pod 'SVProgressHUD'
pod 'CSStickyHeaderFlowLayout'
pod 'InAppSettingsKit'
pod 'MultiSelectSegmentedControl'
pod 'CorePlot'
pod 'Alamofire'
pod 'AlamofireImage'
pod 'AlamofireNetworkActivityIndicator'
pod 'AlamofireNetworkActivityIndicator'
pod 'SwiftyJSON'
pod 'SwiftyDropbox'
pod 'SDCAlertView'

post_install do | installer |
  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods/Pods-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
