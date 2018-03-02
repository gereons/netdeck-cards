//
//  NRDBApi.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    public func decode<T: Decodable>(_ key: Key, as type: T.Type = T.self) throws -> T {
        return try self.decode(T.self, forKey: key)
    }

    public func decodeIfPresent<T: Decodable>(_ key: KeyedDecodingContainer.Key) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
}

struct ApiResponse<T: Codable>: Codable {
    let data: [T]
    let success: Bool
    let version_number: String
    let total: Int
    let imageUrlTemplate: String?

    private let supportedApiVersion = "2.0"
    var valid: Bool {
        return success && version_number == supportedApiVersion && total == data.count
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

    typealias EditingHistory = [String: [String: Int]]  // "timestamp" => [ "code": amount ... ]
    let history: EditingHistory
    
    static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(.id)
        self.date_creation = try container.decode(.date_creation)
        self.date_update = try container.decode(.date_update)
        self.name = try container.decode(.name)
        self.description = try container.decode(.description)
        self.mwl_code = try container.decode(.mwl_code)
        self.cards = try container.decode(.cards)
        if let history = try? container.decode(EditingHistory.self, forKey: .history) {
            self.history = history
        } else {
            self.history = [:]
        }
    }

    static func parse(_ data: Data) -> [NetrunnerDbDeck] {
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = self.dateFormat

            let decoder = JSONDecoder()
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

struct NetrunnerDbAuth: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Double
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct NetrunnerDbCard: Codable {    
    static let X = -2
    
    let advancement_cost: Int?
    let agenda_points: Int?
    let base_link: Int?
    let code: String
    let cost: Int
    let faction_code: String
    let faction_cost: Int?
    let flavor: String?
    let image_url: String?
    let influence_limit: Int?
    let keywords: String?
    let deck_limit: Int
    let memory_cost: Int?
    let minimum_deck_size: Int?
    let pack_code: String
    let position: Int
    let quantity: Int
    let side_code: String
    let strength: Int
    let text: String?
    let title: String
    let trash_cost: Int?
    let type_code: String
    let uniqueness: Bool

    /*
    struct Localized: Codable {
        let title: String?
        let keywords: String?
        let text: String?
        let flavor: String?
        
        enum Keys {
            case title
            case keywords
            case text
            case flavor
        }
    }
    
    let _locale: [String: Localized]?
    */

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.advancement_cost = try container.decodeIfPresent(.advancement_cost)
        self.agenda_points = try container.decodeIfPresent(.agenda_points)
        self.base_link = try container.decodeIfPresent(.base_link)
        self.code = try container.decode(.code)
        self.faction_code = try container.decode(.faction_code)
        self.faction_cost = try container.decodeIfPresent(.faction_cost)
        self.flavor = try container.decodeIfPresent(.flavor)
        self.image_url = try container.decodeIfPresent(.image_url)
        self.influence_limit = try container.decodeIfPresent(.influence_limit)
        self.keywords = try container.decodeIfPresent(.keywords)
        self.deck_limit = try container.decode(.deck_limit)
        self.memory_cost = try container.decodeIfPresent(.memory_cost)
        self.minimum_deck_size = try container.decodeIfPresent(.minimum_deck_size)
        self.pack_code = try container.decode(.pack_code)
        self.position = try container.decode(.position)
        self.quantity = try container.decode(.quantity)
        self.side_code = try container.decode(.side_code)
        self.text = try container.decodeIfPresent(.text)
        self.title = try container.decode(.title)
        self.trash_cost = try container.decodeIfPresent(.trash_cost)
        self.type_code = try container.decode(.type_code)
        self.uniqueness = try container.decode(.uniqueness)
        // self._locale = try container.decodeIfPresent(._locale)
        
        // special treatment for "int value", "null", or not present of cost and strength
        if container.contains(.cost) {
            let cost: Int? = try container.decodeIfPresent(.cost)
            self.cost = cost == nil ? NetrunnerDbCard.X : cost!
        } else {
            self.cost = -1
        }
        if container.contains(.strength) {
            let str: Int? = try container.decodeIfPresent(.strength)
            self.strength = str == nil ? NetrunnerDbCard.X : str!
        } else {
            self.strength = -1
        }
    }

    /*
    func getLocalized(_ key: Localized.Keys, for language: String) -> String {
        var localized: String?
        if let loc = self._locale?[language] {
            switch key {
            case .title: localized = loc.title
            case .keywords: localized = loc.keywords
            case .text: localized = loc.text
            case .flavor: localized = loc.flavor
            }
        }
        if let loc = localized {
            return loc
        } else {
            switch key {
            case .title: return self.title
            case .keywords: return self.keywords ?? ""
            case .text: return self.text ?? ""
            case .flavor: return self.flavor ?? ""
            }
        }
    }
    */
 }

