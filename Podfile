platform :ios, '7.1'
inhibit_all_warnings!
pod 'DTCoreText'
pod 'AFNetworking', '~> 2.0'
pod 'SVProgressHUD'
pod 'TestFlightSDK'
pod 'Dropbox-Sync-API-SDK'
pod 'GRMustache'
pod 'CorePlot'
pod 'libextobjc'
pod 'CSStickyHeaderFlowLayout'
# pod 'SDCAlertView'
pod 'RBBAnimation'
pod 'SDCAutoLayout'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-acknowledgements.markdown', 'NRDB/Acknowledgements.html', :remove_destination => true)
end

class ::Pod::Generator::Acknowledgements
  def header_title
      ""
  end
  def header_text
      "<html><head><style type='text/css'>pre { font-family: 'HelveticaNeue-Light'; white-space: pre-wrap; }</style></head><body><pre>"
  end
  def footnote_text
      "</pre></body></html>"
  end
end

