source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.2'
inhibit_all_warnings!
use_frameworks!

pod 'Fabric'
pod 'Crashlytics'

pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0' # -> Alamofire
pod 'SVProgressHUD'
pod 'Dropbox-Sync-API-SDK' # -> use new DB api?
pod 'GRMustache' # -> GRMustache.swift
pod 'libextobjc' # -> remove?
pod 'CSStickyHeaderFlowLayout'
pod 'SDCAlertView', '~> 2.5.4' # -> use v3.0
pod 'InAppSettingsKit'
pod 'MultiSelectSegmentedControl'

# already swift/swift-ready
pod 'CorePlot'
pod 'PromiseKit/CorePromise'
pod 'PromiseKit-AFNetworking'
# pod 'SwiftyJSON'

post_install do | installer |
  require 'fileutils'
  system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods/Pods-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
