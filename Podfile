platform :ios, '7.1'
inhibit_all_warnings!
pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0'
pod 'SVProgressHUD'
pod 'TestFlightSDK'
pod 'Dropbox-Sync-API-SDK', :podspec => 'Dropbox.podspec.json'
pod 'GRMustache'
pod 'CorePlot'
pod 'libextobjc'
pod 'CSStickyHeaderFlowLayout'
# pod 'SDCAlertView'
pod 'RBBAnimation'
pod 'SDCAutoLayout'

post_install do | installer |
  require 'fileutils'
  # FileUtils.cp_r('Pods/Pods-acknowledgements.markdown', 'NRDB/Acknowledgements.html', :remove_destination => true)
  system("awk -f ackhtml.awk <Pods/Pods-acknowledgements.markdown >NRDB/Acknowledgements.html")
end
