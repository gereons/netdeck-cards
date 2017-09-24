//
//  DeckExport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 10.02.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import SVProgressHUD

enum ExportFormat {
    case plainText
    case markdown
    case bbCode
}

class DeckExport {
    
    static let APP_NAME = "Net Deck"
    static let APP_URL = "http://appstore.com/netdeck"

    static func asPlaintextString(_ deck: Deck) -> String {
        return self.textExport(deck, as: .plainText)
    }
    
    static func asPlaintext(_ deck: Deck) {
        let s = self.asPlaintextString(deck)
        let filename = deck.name + ".txt"
        self.writeToDropbox(s, filename:filename, deckType:"Plain Text Deck".localized(), autoSave:false)
    }
    
    static func asMarkdownString(_ deck: Deck) -> String {
        return self.textExport(deck, as: .markdown)
    }
    
    static func asMarkdown(_ deck: Deck) {
        let s = self.asMarkdownString(deck)
        let filename = deck.name + ".md"
        self.writeToDropbox(s, filename:filename, deckType:"Markdown Deck".localized(), autoSave:false)
    }
    
    static func asBBCodeString(_ deck: Deck) -> String {
        return self.textExport(deck, as: .bbCode)
    }
    
    static func asBBCode(_ deck: Deck) {
        let s = self.asBBCodeString(deck)
        let filename = deck.name + ".bbc"
        self.writeToDropbox(s, filename:filename, deckType:"BBCode Deck".localized(), autoSave:false)
    }
    
    static func asOctgn(_ deck: Deck, autoSave: Bool) {
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
            
            let filename = deck.name + ".o8d"
            self.writeToDropbox(xml, filename: filename, deckType: "OCTGN Deck".localized(), autoSave:autoSave)
        }
    }
    
    static func xmlEscape(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    static func writeToDropbox(_ content: String, filename: String, deckType: String, autoSave: Bool) {
        Dropbox.saveFile(content, filename: filename) { ok in
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
    
    static func textExport(_ deck: Deck, as fmt: ExportFormat) -> String {
        let data = deck.dataForTableView(.byType)
        let sections = data.sections
        let cardsArray = data.values
        
        let eol = fmt == .markdown ? "  \n" : "\n"
        
        var s = deck.name + eol + eol
        if let identity = deck.identity {
            s += identity.name
            s += " " + self.italics("(" + identity.packName + ")", fmt)
            s += eol
        }
        
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
                // s += " " + self.italics("(" + cc.card.packName + ")", fmt)

                let uInf = deck.universalInfluenceFor(cc)
                let inf = max(0, deck.influenceFor(cc) - uInf)
                
                let color = Faction.hexColor(for: cc.card.faction)
                if inf > 0 {
                    s += " " + self.color(self.dots(inf), color, fmt)
                }
                let penalty = cc.card.mwlPenalty(deck.mwl)
                if penalty > 0 {
                    s += " " + self.color(self.stars(cc.count * penalty), color, fmt)
                }
                if cc.card.restricted(deck.mwl) {
                    s += " ⊛"
                }
                if cc.card.banned(deck.mwl) {
                    s += " ⊖"
                }
                s += eol
            }
        }
        
        s += eol
        let deckSize: Int = deck.identity?.minimumDecksize ?? 0
        s += "\(deck.size) cards (minimum \(deckSize))" + eol
        if deck.mwlPenalty > 0 {
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
        
        let reasons = deck.checkValidity()
        if reasons.count > 0 {
            s += "Deck is invalid:" + eol
            reasons.forEach {
                s += "  " + $0 + eol
            }
        }
        
        s += eol + "Deck built with " + self.link(APP_NAME, APP_URL, fmt) + eol
        
        if let notes = deck.notes, notes.length > 0 {
            s += eol + notes + eol
        }
        
        return s;
    }
    
    static func stars(_ count: Int) -> String {
        return nTimes("☆", count)
    }
    
    static func dots(_ count: Int) -> String {
        return nTimes("•", count)
    }
    
    static func nTimes(_ str: String, _ count: Int) -> String {
        var s = ""
        
        for i in 0..<count {
            s += str
            if (i+1)%5 == 0 && i < count-1 {
                s += " "
            }
        }
        return s
    }
    
    static func italics(_ s: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s
        case .markdown: return "_" + s + "_"
        case .bbCode: return "[i]" + s + "[/i]"
        }
    }
    
    static func bold(_ s: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s
        case .markdown: return "**" + s + "**"
        case .bbCode: return "[b]" + s + "[/b]"
        }
    }
    
    static func color(_ s: String, _ color: UInt, _ format: ExportFormat) -> String {
        switch format {
        case .plainText, .markdown:
            return s
        case .bbCode:
            let hexColor = String(color, radix: 16)
            return "[color=#\(hexColor)]\(s)[/color]"
        }
    }
    
    static func link(_ s: String, _ target: String, _ format: ExportFormat) -> String {
        switch format {
        case .plainText: return s + " " + target
        case .markdown: return "[\(s)](\(target))"
        case .bbCode: return "[url=\(target)]\(s)[/url]"
        }
    }

}
