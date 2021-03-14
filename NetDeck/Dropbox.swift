//
//  Dropbox
//  NetDeck
//
//  Created by Gereon Steffens on 13.02.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

// wrapper class for Dropbox API calls

import SwiftyDropbox
import SwiftyUserDefaults

final class Dropbox {
    
    static func setup() {
        DropboxClientsManager.setupWithAppKey("4mhw6piwd9wqti3")
        
        let clientOk = DropboxClientsManager.authorizedClient != nil
        // print("dropbox setup, clientOk=\(clientOk)")
        if !clientOk {
            Defaults[.useDropbox] = false
        }
    }

    static func handleURL(_ url: URL, completion: @escaping (Bool) -> Void) {

        let ok = DropboxClientsManager.handleRedirectURL(url) { authResult in
            switch authResult {
            case .success:
                print("Success! User is logged into Dropbox.")
                completion(true)
            case .error(let error, let description):
                print("Error: \(error) \(String(describing: description))")
                completion(false)
            case .cancel:
                print("Cancelled")
                completion(false)
            case .none:
                print("Unknown")
                completion(false)
            }
        }

        print("handler status: \(ok)")
    }
    
    static func authorizeFromController(_ controller: UIViewController) {
        if DropboxClientsManager.authorizedClient == nil {
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                          controller: controller,
                                                          openURL: { url in UIApplication.shared.open(url) } )
        } else {
            print("User is already authorized!")
        }
    }
    
    static func unlinkClient() {
        DropboxClientsManager.unlinkClients()
    }
    
    static func listFiles(_ completion: @escaping ([String])->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        _ = client.files.listFolder(path: "").response { response, error in
            if let result = response {
                let names = result.entries.map { $0.name }
                completion(names)
            }
        }
    }
    
    static func downloadFiles(_ names: [String], toDirectory: String, completion: @escaping ()->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        var count = 0
        for name in names {
            _ = client.files.download(path: "/" + name, destination: { (url, response) -> URL in
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
        
        if let data = content.data(using: .utf8) {
            print("\(data)")
            _ = client.files.upload(path: "/" + filename, mode: .overwrite, autorename: false, clientModified: nil, mute: false, input: data).response { response, error in
                completion(error == nil)
            }
        } else {
            completion(false)
        }
    }
}
