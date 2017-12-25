//
//  NRDBApi.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

struct ApiResponse<T: Codable>: Codable {
    var data: [T]
    let success: Bool
    let version_number: String
    let total: Int

    private let supportedNrdbApiVersion = "2.0"
    var valid: Bool {
        return success && version_number == supportedNrdbApiVersion && total == data.count
    }
}

struct NetrunnerDbDeck: Codable {
    let id: Int
    let date_creation: Date
    let date_update: Date
    let name: String
    let description: String
    let mwl_code: String?
    let cards: [String: Int]
    let history: [String: [String: Int]]?

    static func parse(_ data: Data) -> [NetrunnerDbDeck] {
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ'"
            formatter.timeZone = TimeZone(identifier: "GMT")
            decoder.dateDecodingStrategy = .formatted(formatter)

            let result = try decoder.decode(ApiResponse<NetrunnerDbDeck>.self, from: data)
            if result.valid {
                return result.data
            }
        }
        catch let error {
            print("\(error)")
        }
        return []
    }
}
