platform :ios, '7.1'
inhibit_all_warnings!
pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0'
# pod 'SVProgressHUD', :head
pod 'SVProgressHUD', :path => '~/dev/SVProgressHUD', :branch => 'master'
pod 'TestFlightSDK'
pod 'Dropbox-Sync-API-SDK'
pod 'GRMustache'
pod 'CorePlot'
pod 'libextobjc'
pod 'CSStickyHeaderFlowLayout'
pod 'SDCAlertView', :head
pod 'YOLOKit'

post_install do | installer |
  require 'fileutils'
  # FileUtils.cp_r('Pods/Pods-acknowledgements.markdown', 'NRDB/Acknowledgements.html', :remove_destination => true)
  system("awk -f ackhtml.awk <Pods/Pods-acknowledgements.markdown >NRDB/Acknowledgements.html")
end
