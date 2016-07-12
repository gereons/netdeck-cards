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
    case PlainText
    case Markdown
    case BBCode
}

@objc class DeckExport: NSObject {
    
    static let APP_NAME = "Net Deck"
    static let APP_URL = "http://appstore.com/netdeck"

    class func asPlaintextString(deck: Deck) -> String {
        return self.textExport(deck, .PlainText)
    }
    
    class func asPlaintext(deck: Deck) {
        let s = self.asPlaintextString(deck)
        let filename = (deck.name ?? "deck") + ".txt"
        self.writeToDropbox(s, filename:filename, deckType:"Plain Text Deck".localized(), autoSave:false)
    }
    
    class func asMarkdownString(deck: Deck) -> String {
        return self.textExport(deck, .Markdown)
    }
    
    class func asMarkdown(deck: Deck) {
        let s = self.asMarkdownString(deck)
        let filename = (deck.name ?? "deck") + ".md"
        self.writeToDropbox(s, filename:filename, deckType:"Markdown Deck".localized(), autoSave:false)
    }
    
    class func asBBCodeString(deck: Deck) -> String {
        return self.textExport(deck, .BBCode)
    }
    
    class func asBBCode(deck: Deck) {
        let s = self.asBBCodeString(deck)
        let filename = (deck.name ?? "deck") + ".bbc"
        self.writeToDropbox(s, filename:filename, deckType:"BBCode Deck".localized(), autoSave:false)
    }
    
    class func asOctgn(deck: Deck, autoSave: Bool) {
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
            
            if let notes = deck.notes where notes.length > 0 {
                xml += "<notes><![CDATA[\(notes)]]></notes>\n"
            }
            xml += "</deck>\n"
            
            let filename = (deck.name ?? "") + ".o8d"
            self.writeToDropbox(xml, filename: filename, deckType: "OCTGN Deck".localized(), autoSave:autoSave)
        }
    }
    
    class func xmlEscape(s: String) -> String {
        return s
            .stringByReplacingOccurrencesOfString("&", withString: "&amp;")
            .stringByReplacingOccurrencesOfString("<", withString: "&lt;")
            .stringByReplacingOccurrencesOfString(">", withString: "&gt;")
            .stringByReplacingOccurrencesOfString("'", withString: "&#39;")
            .stringByReplacingOccurrencesOfString("\"", withString: "&quot;")
    }

    class func writeToDropbox(content: String, filename: String, deckType: String, autoSave: Bool) {
        DropboxWrapper.saveFileToDropbox(content, filename: filename) { ok in
            if autoSave {
                return
            }
            
            if ok {
                SVProgressHUD.showSuccessWithStatus(String(format: "%@ exported".localized(), deckType))
            } else {
                SVProgressHUD.showErrorWithStatus(String(format:"Error exporting %@".localized(), deckType))
            }
        }
    }
    
    class func textExport(deck: Deck, _ fmt: ExportFormat) -> String {
        let data = deck.dataForTableView(.ByType)
        let cardsArray = data.values as! [[CardCounter]]
        let sections = data.sections as! [String]
        
        let eol = fmt == .Markdown ? "  \n" : "\n"
        
        var s = (deck.name ?? "") + eol + eol
        if let identity = deck.identity {
            s += identity.name
            s += " " + self.italics("(" + identity.packName + ")", fmt)
            s += eol
        }
        
        let useMWL = deck.mwl != NRMWL.None
        for i in 0..<sections.count {
            let cards = cardsArray[i]
            let cc = cards[0]
            if cc.isNull || cc.card.type == .Identity {
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
        
        if deck.identity?.role == .Corp {
            s += "\(deck.agendaPoints) agenda points" + eol
        }
        let set = PackManager.mostRecentPackUsedInDeck(deck)
        s += "Cards up to \(set)" + eol
        
        s += eol + "Deck built with " + self.link(APP_NAME, APP_URL, fmt) + eol
        
        if let notes = deck.notes where notes.length > 0 {
            s += eol + notes + eol
        }
        
        s += self.localUrlForDeck(deck) + eol
        
        return s;
    }
    
    class func stars(count: Int) -> String {
        return nTimes("☆", count)
    }
    
    class func dots(count: Int) -> String {
        return nTimes("•", count)
    }
    
    class func nTimes(str: String, _ count: Int) -> String {
        var s = ""
        
        for i in 0..<count {
            s += str
            if (i+1)%5 == 0 && i < count-1 {
                s += " "
            }
        }
        return s
    }
    
    class func localUrlForDeck(deck: Deck) -> String {
        var dict = [String: String]()
        if let id = deck.identity {
            dict[id.code] = "1"
        }
        for cc in deck.cards {
            dict[cc.card.code] = "\(cc.count)"
        }
        if let name = deck.name where name.length > 0 {
            dict["name"] = name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        }
        
        let keys = dict.keys.sort{ $0 < $1 }
        var url = ""
        var sep = ""
        for k in keys {
            let v = dict[k]!
            url += sep + k + "=" + v
            sep = "&"
        }
        
        let compressed = GZip.gzipDeflate(url.dataUsingEncoding(NSUTF8StringEncoding))
        let base64url = compressed.base64EncodedStringWithOptions([])
        
        return "netdeck://load/" + base64url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())!
    }

    class func italics(s: String, _ format: ExportFormat) -> String {
        switch format {
        case .PlainText: return s
        case .Markdown: return "_" + s + "_"
        case .BBCode: return "[i]" + s + "[/i]"
        }
    }
    
    class func bold(s: String, _ format: ExportFormat) -> String {
        switch format {
        case .PlainText: return s
        case .Markdown: return "**" + s + "**"
        case .BBCode: return "[b]" + s + "[/b]"
        }
    }
    
    class func color(s: String, _ color: UInt, _ format: ExportFormat) -> String {
        switch format {
        case .PlainText, .Markdown: return s
        case .BBCode: return "[color=#\(color)]" + s + "[/color]"
        }
    }
    
    class func link(s: String, _ target: String, _ format: ExportFormat) -> String {
        switch format {
        case .PlainText: return s + " " + target
        case .Markdown: return "[\(s)](\(target))"
        case .BBCode: return "[url=\(target)]" + s + "[/url]"
        }
    }

}