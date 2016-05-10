source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
inhibit_all_warnings!
platform :ios, '9.2'
target 'NetDeck' do
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
  pod 'SwiftKeychainWrapper'
end

post_install do | installer |
  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
