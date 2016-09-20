//
//  DeckExport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 10.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import SVProgressHUD

enum ExportFormat {
    case plainText
    case markdown
    case bbCode
}

class DeckExport: NSObject {
    
    static let APP_NAME = "Net Deck"
    static let APP_URL = "http://appstore.com/netdeck"

    class func asPlaintextString(_ deck: Deck) -> String {
        return self.textExport(deck, .plainText)
    }
    
    class func asPlaintext(_ deck: Deck) {
        let s = self.asPlaintextString(deck)
        let filename = (deck.name ?? "deck") + ".txt"
        self.writeToDropbox(s, filename:filename, deckType:"Plain Text Deck".localized(), autoSave:false)
    }
    
    class func asMarkdownString(_ deck: Deck) -> String {
        return self.textExport(deck, .markdown)
    }
    
    class func asMarkdown(_ deck: Deck) {
        let s = self.asMarkdownString(deck)
        let filename = (deck.name ?? "deck") + ".md"
        self.writeToDropbox(s, filename:filename, deckType:"Markdown Deck".localized(), autoSave:false)
    }
    
    class func asBBCodeString(_ deck: Deck) -> String {
        return self.textExport(deck, .bbCode)
    }
    
    class func asBBCode(_ deck: Deck) {
        let s = self.asBBCodeString(deck)
        let filename = (deck.name ?? "deck") + ".bbc"
        self.writeToDropbox(s, filename:filename, deckType:"BBCode Deck".localized(), autoSave:false)
    }
    
    class func asOctgn(_ deck: Deck, autoSave: Bool) {
        if let identity = deck.identity {
            let name = self.xmlEscape(identity.name)
            var xml = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n" +
                "<deck game=\"0f38e453-26df-4c04-9d67-6d43de939c77\">\n" +
                "<section name=\"Identity\">\n" +
                "  <card qty=\"1\" id=\"\(identity.octgnCode)\">\(name)</card>\n" +
                "</section>\n" +
                "<section name=\"R&amp;D / Stack\">\n"
            
            for cc in deck.cards {
                let name = self.xmlEscape(cc.card.name)
                xml += "  <card qty=\"\(cc.count)\" id=\"\(cc.card.octgnCode)\">\(name)</card>\n"
            }
            xml += "</section>\n"
            
            if let notes = deck.notes , notes.length > 0 {
                xml += "<notes><![CDATA[\(notes)]]></notes>\n"
            }
            xml += "</deck>\n"
            
            let filename = (deck.name ?? "") + ".o8d"
            self.writeToDropbox(xml, filename: filename, deckType: "OCTGN Deck".localized(), autoSave:autoSave)
        }
    }
    
    class func xmlEscape(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    class func writeToDropbox(_ content: String, filename: String, deckType: String, autoSave: Bool) {
        DropboxWrapper.saveFileToDropbox(content, filename: filename) { ok in
            if autoSave {
                return
            }
            
            if ok {
                SVProgressHUD.showSuccess(withStatus: String(format: "%@ exported".localized(), deckType))
            } else {
                SVProgressHUD.showError(withStatus: String(format:"Error exporting %@".localized(), deckType))
            }
        }
    }
    
    class func textExport(_ deck: Deck, _ fmt: ExportFormat) -> String {
        let data = deck.dataForTableView(.byType)
        let cardsArray = data.values as! [[CardCounter]]
        let sections = data.sections as! [String]
        
        let eol = fmt == .markdown ? "  \n" : "\n"
        
        var s = (deck.name ?? "") + eol + eol
        if let identity = deck.identity {
            s += identity.name
            s += " " + self.italics("(" + identity.packName + ")", fmt)
            s += eol
        }
        
        let useMWL = deck.mwl != NRMWL.none
        for i in 0..<sections.count {
            let cards = cardsArray[i]
            let cc = cards[0]
            if cc.isNull || cc.card.type == .identity {
                continue
            }
            
            var cnt = 0
            for cc in cards {
                cnt += cc.count
            }
            s += eol + self.bold(sections[i], fmt) + " (\(cnt))" + eol
            
            for cc in cards {
                s += "\(cc.count)x " + cc.card.name
                s += " " + self.italics("(" + cc.card.packName + ")", fmt)

                let inf = deck.influenceFor(cc)
                if inf > 0 {
                    s += " " + self.color(self.dots(inf), cc.card.factionHexColor, fmt)
                }
                if useMWL && cc.card.isMostWanted(deck.mwl) {
                    s += " " + self.color(self.stars(cc.count), cc.card.factionHexColor, fmt)
                }
                s += eol
            }
        }
        
        s += eol
        let deckSize: Int = deck.identity?.minimumDecksize ?? 0
        s += "\(deck.size) cards (minimum \(deckSize))" + eol
        if useMWL && deck.mwlPenalty > 0 {
            let limit = deck.identity?.influenceLimit ?? 0
            s += "\(deck.influence)/\(deck.influenceLimit) (=\(limit)-\(deck.mwlPenalty)☆) influence used" + eol
        } else {
            s += "\(deck.influence)/\(deck.influenceLimit) influence used" + eol
        }
        
        if deck.identity?.role == .corp {
            s += "\(deck.agendaPoints) agenda points" + eol
        }
        let set = PackManager.mostRecentPackUsedIn(deck: deck)
        s += "Cards up to \(set)" + eol
        
        s += eol + "Deck built with " + self.link(APP_NAME, APP_URL, fmt) + eol
        
        if let notes = deck.notes , notes.length > 0 {
            s += eol + notes + eol
        }
        
        s += self.localUrlForDeck(deck) + eol
        
        return s;
    }
    
    class func stars(_ count: Int) -> String {
        return nTimes("☆", count)
    }
    
    class func dots(_ count: Int) -> String {
        return nTimes("•", count)
    }
    
    class func nTimes(_ str: String, _ count: Int) -> String {
        var s = ""
        
        for i in 0..<count {
            s += str
            if (i+1)%5 == 0 && i < count-1 {
                s += " "
            }
        }
        return s
    }
    
    class func localUrlForDeck(_ deck: Deck) -> String {
        var dict = [String: String]()
        if let id = deck.identity {
            dict[id.code] = "1"
        }
        for cc in deck.cards {
            dict[cc.card.code] = "\(cc.count)"
        }
        if let name = deck.name , name.length > 0 {
            dict["name"] = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        }
        
        let keys = dict.keys.sorted{ $0 < $1 }
        var url = ""
        var sep = ""
        for k in keys {
            let v = dict[k]!
            url += sep + k + "=" + v
            sep = "&"
        }
        
        let compressed = GZip.gzipDeflate(url.data(using: String.Encoding.utf8))
        let base64url = compressed?.base64EncodedString(options: [])
        
        return "netdeck://load/" + base64url!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
    }

    class func italics(_ s: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s
        case .markdown: return "_" + s + "_"
        case .bbCode: return "[i]" + s + "[/i]"
        }
    }
    
    class func bold(_ s: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s
        case .markdown: return "**" + s + "**"
        case .bbCode: return "[b]" + s + "[/b]"
        }
    }
    
    class func color(_ s: String, _ color: UInt, _ format: ExportFormat) -> String {
        switch format {
        case .plainText, .markdown: return s
        case .bbCode: return "[color=#\(color)]" + s + "[/color]"
        }
    }
    
    class func link(_ s: String, _ target: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s + " " + target
        case .markdown: return "[\(s)](\(target))"
        case .bbCode: return "[url=\(target)]" + s + "[/url]"
        }
    }

}
