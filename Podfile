source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
inhibit_all_warnings!
platform :ios, '9.2'
target 'NetDeck' do
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'DTCoreText'
    pod 'SVProgressHUD'
    pod 'InAppSettingsKit'
    pod 'MultiSelectSegmentedControl'
    pod 'CorePlot'
    pod 'DZNEmptyDataSet'
    pod 'DeviceKit'

    pod 'SwiftyDropbox'
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper'
    pod 'SDCAlertView'
    pod 'EasyTipView', :git => "https://github.com/gereons/EasyTipView"
    pod 'SwiftyUserDefaults'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'CorePlot'
            target.build_configurations.each do |config|
                config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
            end
        end
    end

    require 'fileutils'
    system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
