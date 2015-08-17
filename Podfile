source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.3'
inhibit_all_warnings!
pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0'
pod 'SVProgressHUD'
pod 'Dropbox-Sync-API-SDK'
pod 'GRMustache'
pod 'CorePlot'
pod 'libextobjc'
pod 'CSStickyHeaderFlowLayout'
pod 'SDCAlertView'
pod 'InAppSettingsKit'
pod 'PromiseKit', '1.5.3'
pod 'PromiseKit-AFNetworking'

post_install do | installer |
  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods/Pods-acknowledgements.markdown' >NRDB/Acknowledgements.html")
end
