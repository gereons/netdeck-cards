source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.1'
inhibit_all_warnings!
pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0'
pod 'SVProgressHUD', :head
pod 'TestFlightSDK'
pod 'Dropbox-Sync-API-SDK'
pod 'GRMustache'
pod 'CorePlot'
pod 'libextobjc'
pod 'CSStickyHeaderFlowLayout'
pod 'SDCAlertView'
pod 'YOLOKit'
pod 'InAppSettingsKit', :head

post_install do | installer |
  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods/Pods-acknowledgements.markdown' >NRDB/Acknowledgements.html")
end
