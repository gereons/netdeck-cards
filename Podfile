use_frameworks!
inhibit_all_warnings!
platform :ios, '12.4'

def pods
    pod 'Sentry'
    pod 'SVProgressHUD'
    pod 'InAppSettingsKit'
    pod 'MultiSelectSegmentedControl'
    pod 'CorePlot'
    pod 'DZNEmptyDataSet'
    pod 'DeviceKit'

    pod 'SwiftyDropbox', :git => "https://github.com/gereons/SwiftyDropbox"
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper'
    pod 'SDCAlertView'
    pod 'EasyTipView'
    pod 'SwiftyUserDefaults', '~> 3'
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
