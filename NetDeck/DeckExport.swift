//
//  DeckExport.swift
//  NetDeck
//
//  Created by Gereon Steffens on 10.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

enum ExportFormat {
    case PlainText
    case Markdown
    case BBCode
}

class xDeckExport {
    
    static let APP_NAME = "Net Deck"
    static let APP_URL = "http://appstore.com/netdeck"

    class func asPlaintextString(deck: Deck) -> String {
        return self.textExport(deck, .PlainText)
    }
    
    class func asMarkdownString(deck: Deck) -> String {
        return self.textExport(deck, .Markdown)
    }
    
    class func asBBCodeString(deck: Deck) -> String {
        return self.textExport(deck, .BBCode)
    }
    

    class func textExport(deck: Deck, _ fmt: ExportFormat) -> String {
        let data = deck.dataForTableView(.Type)
        let cardsArray = data.values as! [[CardCounter]]
        let sections = data.sections as! [String]
        
        let eol = fmt == .Markdown ? "  \n" : "\n"
        
        var s = (deck.name ?? "") + eol + eol
        if let identity = deck.identity {
            s += identity.name + self.italics("(" + identity.setName + ")", fmt) + eol
        }
        
        let useMWL = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_NAPD_MWL)
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
                s += "\(cc.count)x " + cc.card.name + self.italics("(" + cc.card.setName + ")", fmt)
                let inf = deck.influenceFor(cc)
                if inf > 0 {
                    s += " " + self.color(self.dots(inf), cc.card.factionHexColor, fmt)
                }
                if useMWL && cc.card.isMostWanted {
                    s += " (MWL)"
                }
                s += eol
            }
        }
        
        s += eol
        s += "Cards in deck: \(deck.size) (min \(deck.identity?.minimumDecksize)" + eol
        if useMWL {
            s += "\(deck.influence)/\(deck.influenceLimit) (\(deck.identity?.influenceLimit)-\(deck.mwlPenalty) influence used" + eol
            s += "\(deck.cardsFromMWL) cards from MWL" + eol
        } else {
            s += "\(deck.influence)/\(deck.influenceLimit) influence used" + eol
        }
        
        if deck.identity?.role == .Corp {
            s += "Agenda Points: \(deck.agendaPoints)" + eol
        }
        let set = CardSets.mostRecentSetUsedInDeck(deck)
        s += "Cards up to \(set)" + eol
        
        s += eol + "Deck built with " + self.link(APP_NAME, APP_URL, fmt) + eol
        
        if deck.notes?.length > 0 {
            s += eol + deck.notes! + eol
        }
        
        s += eol + xDeckExport.localUrlForDeck(deck) + eol
        
        return s;
    }
    
    class func writeToDropbox() {
    }
    
    class func dots(influence: Int) -> String {
        var s = ""
        
        for i in 0..<influence {
            s += "·"
            if (i+1)%5 == 0 && i < influence-1 {
                s += " "
            }
        }
        return s
    }
    
    class func localUrlForDeck(deck: Deck) -> String {
        return "netdeck://<local url>"
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
        case .PlainText,
        .Markdown: return s
        case .BBCode: return "[color=#\(color)]" + s + "[/color]"
        }
    }
    
    class func link(s: String, _ target: String, _ format: ExportFormat) -> String {
        switch format {
        case .PlainText: return s + " " + target
        case .Markdown: return "[\(s)](\(target))"
        case .BBCode: return "[b]" + s + "[/b]"
        }
    }

}