//
//  Dropbox
//  NetDeck
//
//  Created by Gereon Steffens on 13.02.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

// wrapper class for Dropbox API calls

import SwiftyDropbox
import SwiftyUserDefaults

class Dropbox {
    
    static func setup() {
        DropboxClientsManager.setupWithAppKey("4mhw6piwd9wqti3")
        
        let clientOk = DropboxClientsManager.authorizedClient != nil
        // print("dropbox setup, clientOk=\(clientOk)")
        if !clientOk {
            Defaults[.useDropbox] = false
        }
    }

    static func handleURL(_ url: URL) -> Bool {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success:
                print("Success! User is logged into Dropbox.")
                return true
            case .error(let error, let description):
                print("Error: \(error) \(description)")
                return false
            case .cancel:
                print("Cancelled")
                return false
            }
        }
        
        return false
    }
    
    static func authorizeFromController(_ controller: UIViewController) {
        if DropboxClientsManager.authorizedClient == nil {
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                          controller: controller,
                                                          openURL: { url in UIApplication.shared.openURL(url) } )
        } else {
            print("User is already authorized!")
        }
    }
    
    static func unlinkClient() {
        DropboxClientsManager.unlinkClients()
    }
    
    static func listFiles(_ completion: @escaping ([String])->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        let _ = client.files.listFolder(path: "").response { response, error in
            if let result = response {
                var names = [String]()
                for entry in result.entries {
                    names.append(entry.name)
                }
                completion(names)
            }
        }
    }
    
    static func downloadFiles(_ names: [String], toDirectory: String, completion: @escaping ()->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        var count = 0
        for name in names {
            let _ = client.files.download(path: "/" + name, destination: { (url, response) -> URL in
                let path = toDirectory.appendPathComponent(name)
                let destination = URL(fileURLWithPath: path)
                return destination
            }).response { response, error in
                if let (metadata, _) = response {
                    let attrs = [ FileAttributeKey.modificationDate: metadata.clientModified ]
                    let path = toDirectory.appendPathComponent(name)
                    _ = try? FileManager.default.setAttributes(attrs, ofItemAtPath: path)
                }
                count += 1
                if count == names.count {
                    completion()
                }
            }
        }
    }
    
    static func saveFile(_ content: String, filename: String, completion: @escaping (Bool)->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        if let data = content.data(using: String.Encoding.utf8) {
            print("\(data)")
            let _ = client.files.upload(path: "/" + filename, mode: .overwrite, autorename: false, clientModified: nil, mute: false, input: data).response { response, error in
                completion(error == nil)
            }
        } else {
            completion(false)
        }
    }
}
