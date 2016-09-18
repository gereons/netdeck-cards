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
    pod 'CorePlot', :git => 'https://github.com/core-plot/core-plot.git', :branch => 'release-2.2'
    pod 'DZNEmptyDataSet'

    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper', :git => 'https://github.com/jrendel/SwiftKeychainWrapper.git', :branch => 'master'
    pod 'SwiftyJSON', :git => 'https://github.com/IBM-Swift/SwiftyJSON'
    pod 'SwiftyDropbox'
    pod 'SDCAlertView'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['SWIFT_VERSION'] = "3.0"
    end
  end

  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
