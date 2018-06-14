use_frameworks!
# use_modular_headers!
inhibit_all_warnings!
platform :ios, '9.2'

def pods
#    pod 'Fabric'
#    pod 'Crashlytics'
    pod 'SVProgressHUD'
    pod 'InAppSettingsKit'
    pod 'MultiSelectSegmentedControl'
    pod 'CorePlot', :git => "https://github.com/core-plot/core-plot", :branch => 'release-2.3'
    pod 'DZNEmptyDataSet'
    pod 'DeviceKit'

    pod 'SwiftyDropbox', :git => "https://github.com/gereons/SwiftyDropbox"
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper'
    pod 'SDCAlertView'
    pod 'EasyTipView', :git => "https://github.com/gereons/EasyTipView"
    pod 'SwiftyUserDefaults'
end

target 'NetDeck' do
    pods
end

target 'NetDeckTests' do
    pods
end

post_install do |installer|
    require 'fileutils'
    system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
