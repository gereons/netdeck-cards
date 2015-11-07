//
//  Card.m
//  Net Deck
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2015 Gereon Steffens. All rights reserved.
//

#import "Card.h"
#import "CardSets.h"
#import "CardManager.h"
#import "CardType.h"
#import "Faction.h"
#import "SettingsKeys.h"
#import <DTCoreText.h>

@interface Card()

@property NSAttributedString* attributedText;

@property (readwrite) BOOL isCore;

@end

@implementation Card

static NSDictionary* roleCodes;
static NSArray* max1InDeck;
static NSMutableArray* multiIce;
static NSDictionary* coreTextOptions;
static NSDictionary* factionColors;
static NSDictionary* cropValues;

+(void) initialize
{
    max1InDeck = MAX_1_PER_DECK;

    multiIce = [NSMutableArray array];
    
    roleCodes = @{ @"runner": @(NRRoleRunner), @"corp": @(NRRoleCorp) };
    
    coreTextOptions = @{
        DTUseiOS6Attributes: @(YES),
        DTDefaultFontFamily: @"Helvetica",
        DTDefaultFontSize: @(13)
    };
    
    factionColors = @{
        @(NRFactionJinteki):      @(0x940c00),
        @(NRFactionNBN):          @(0xd7a32d),
        @(NRFactionWeyland):      @(0x2d7868),
        @(NRFactionHaasBioroid):  @(0x6b2b8a),
        @(NRFactionShaper):       @(0x6ab545),
        @(NRFactionCriminal):     @(0x4f67b0),
        @(NRFactionAnarch):       @(0xf47c28),
        @(NRFactionAdam):         @(0xae9543),
        @(NRFactionApex):         @(0xa8403d),
        @(NRFactionSunnyLebeau):  @(0x776e6f),
    };
    
    cropValues = @{
        @(NRCardTypeAgenda): @15,
        @(NRCardTypeAsset): @20,
        @(NRCardTypeEvent): @10,
        @(NRCardTypeIdentity): @12,
        @(NRCardTypeOperation): @10,
        @(NRCardTypeHardware): @18,
        @(NRCardTypeIce): @209,
        @(NRCardTypeProgram): @8,
        @(NRCardTypeResource): @11,
        @(NRCardTypeUpgrade): @22,
    };
}

+(Card*) cardByCode:(NSString *)code
{
    return [CardManager cardByCode:code];
}

-(NSAttributedString*) attributedText
{
    if (!self->_attributedText)
    {
        NSString *str = [self.text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        NSAttributedString* attrStr = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:coreTextOptions
                                                                   documentAttributes:nil];
        
        self->_attributedText = attrStr;
    }
    return self->_attributedText;
}

-(NSString*) octgnCode
{
    return [NSString stringWithFormat:@"%@%@", OCTGN_CODE_PREFIX, self.code];
}

-(NSUInteger) factionHexColor
{
    NSNumber* n = factionColors[@(self.faction)];
    return [n unsignedIntegerValue];
}

-(UIColor*) factionColor
{
    NSUInteger rgb = [self factionHexColor];
    return UIColorFromRGB(rgb);
}

-(int) cropY
{
    NSNumber* n = cropValues[@(self.type)];
    return [n intValue];
}

-(NSInteger) owned
{
    if (self.isCore)
    {
        NSInteger cores = [[NSUserDefaults standardUserDefaults] integerForKey:NUM_CORES];
        return cores * self.quantity;
    }
    NSSet* disabledSets = [CardSets disabledSetCodes];
    if ([disabledSets containsObject:self.setCode])
    {
        return 0;
    }
    return self.quantity;
}

-(NSString*) iceType
{
    NSAssert(self.type == NRCardTypeIce, @"not an ice");
    
    if ([multiIce containsObject:self.code])
    {
        return l10n(@"Multi");
    }
    
    NSString* type = [self.subtypes objectAtIndex:0];
    return type == nil ? l10n(@"ICE") : type;
}

-(NSString*) programType
{
    NSAssert(self.type == NRCardTypeProgram, @"not a program");
    
    if (self.strength != -1)
    {
        // only icebreakers have strength
        NSString* type = [self.subtypes objectAtIndex:0];
        return type;
    }
    else
    {
        return self.typeStr;
    }
}

#pragma mark from json

#define JSON_INT(key, attr)          do { NSString* tmp = [json objectForKey:attr]; c->_##key = tmp ? [tmp intValue] : -1; } while (0)
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

+(Card*) cardFromJson:(NSDictionary*)json
{
    Card* c = [Card new];
    
    JSON_STR(code, @"code");
    JSON_STR(name, @"title");
    c->_name = [c->_name stringByReplacingHTMLEntities];
    c->_name_en = c->_name;
    
    JSON_STR(factionStr, @"faction");
    NSString* factionCode = [json objectForKey:@"faction_code"];
    c->_faction = [Faction faction:factionCode];
    NSAssert(c.faction != NRFactionNone, @"no faction for %@", c.code);
    
    JSON_STR(roleStr, @"side");
    NSString* roleCode = [json objectForKey:@"side_code"];
    NSNumber* rc = [roleCodes objectForKey:roleCode.lowercaseString];
    c->_role = rc ? rc.integerValue : NRRoleNone;
    NSAssert(c.role != NRRoleNone, @"no role for %@", c.code);
    
    if (IS_IPHONE && c.type == NRCardTypeIdentity)
    {
        c->_name = [Card shortIdentityName:c.name forRole:c.role andFaction:c.factionStr];
    }
    // remove the "consortium" from weyland's name
    if (c.faction == NRFactionWeyland)
    {
        c->_factionStr = @"Weyland";
    }

    JSON_STR(text, @"text");
    c->_text = [c->_text stringByReplacingHTMLEntities];
    
    JSON_STR(flavor, @"flavor");
    
    JSON_STR(typeStr, @"type");
    NSString* typeCode = [json objectForKey:@"type_code"];
    c->_type = [CardType type:typeCode];
    NSAssert(c.type != NRCardTypeNone, @"no type for %@ (%@)", c.code, c.typeStr);
    
    JSON_STR(setName, @"setname");
    JSON_STR(setCode, @"set_code");
    if (c->_setCode == nil)
    {
        c->_setCode = UNKNOWN_SET;
        c->_setName = UNKNOWN_SET;
    }
    if ([c->_setCode isEqualToString:DRAFT_SET_CODE]) {
        c->_faction = NRFactionNeutral;
    }

    c->_setNumber = [CardSets setNumForCode:c->_setCode];
    c->_isCore = [c.setCode caseInsensitiveCompare:CORE_SET_CODE] == NSOrderedSame;
    
    JSON_STR(subtype, @"subtype");
    if (c.subtype.length == 0)
    {
        c->_subtype = nil;
    }
    if (c.subtype)
    {
        c->_subtype = [c.subtype stringByReplacingOccurrencesOfString:@"G-Mod" withString:@"G-mod"];
        c->_subtype = [c.subtype stringByReplacingOccurrencesOfString:@" – " withString:@" - "]; // fix dashes in german subtypes
        c->_subtypes = [c.subtype componentsSeparatedByString:@" - "];
    }
    
    JSON_INT(number, @"number");
    JSON_INT(quantity, @"quantity");
    
    JSON_BOOL(unique, @"uniqueness");
    
    if (c.type == NRCardTypeIdentity)
    {
        JSON_INT(influenceLimit, @"influencelimit");
        JSON_INT(minimumDecksize, @"mindecksize");
        JSON_INT(minimumDecksize, @"minimumdecksize");
        JSON_INT(baseLink, @"baselink");
    }
    else
    {
        c->_influenceLimit = -1;
        c->_minimumDecksize = -1;
        c->_baseLink = -1;
    }
    if (c.type == NRCardTypeAgenda)
    {
        JSON_INT(advancementCost, @"advancementcost");
        JSON_INT(agendaPoints, @"agendapoints");
    }
    else
    {
        c->_advancementCost = -1;
        c->_agendaPoints = -1;
    }
    JSON_INT(mu, @"memoryunits");
    JSON_INT(strength, @"strength");
    JSON_INT(cost, @"cost");
    JSON_INT(influence, @"factioncost");
    JSON_INT(trash, @"trash");
    
    JSON_STR(imageSrc, @"imagesrc");
    if (c->_imageSrc.length > 0)
    {
        NSString* host = [[NSUserDefaults standardUserDefaults] stringForKey:NRDB_HOST];
        c->_imageSrc = [NSString stringWithFormat:@"http://%@%@", host, c->_imageSrc];
    }
    
    if (c->_imageSrc == nil)
    {
        NSArray* images = [json objectForKey:@"images"];
        if ([images isKindOfClass:[NSArray class]] && images.count > 0)
        {
            NSDictionary* img = images[0];
            c->_imageSrc = [img objectForKey:@"src"];
        }
    }
    
    if (c->_imageSrc.length == 0)
    {
        c->_imageSrc = nil;
    }
    
    JSON_INT(maxPerDeck, @"limited");
    // TODO: remove this hack for v2.3
    if (c->_maxPerDeck == 0) {
        c->_maxPerDeck = 3;
    }
    if ([max1InDeck containsObject:c.code] || c.type == NRCardTypeIdentity)
    {
        c->_maxPerDeck = 1;
    }
    
    if (c.isMultiIce)
    {
        [multiIce addObject:c.code];
    }
    
    JSON_STR(ancurLink, @"ancurLink");
    if (c.ancurLink.length == 0)
    {
        c->_ancurLink = nil;
    }
    
    return c;
}

+(NSString*) shortIdentityName:(NSString*)name forRole:(NRRole)role andFaction:(NSString*)faction
{
    // manipulate identity name
    NSRange colon = [name rangeOfString:@": "];
    
    // runner: remove stuff after the colon ("Andromeda: Disposessed Ristie" becomes "Andromeda")
    if (role == NRRoleRunner && colon.location != NSNotFound)
    {
        name = [name substringToIndex:colon.location];
    }
    
    // corp: if faction name is part of the title, remove it ("NBN: The World is Yours*" becomes "The World is Yours*")
    // otherwise, remove stuff after the colon ("Harmony Medtech: Biomedical Pioneer" becomes "Harmony Medtech")
    if (role == NRRoleCorp && colon.location != NSNotFound)
    {
        NSString* f = [faction stringByAppendingString:@": "];
        NSRange range = [name rangeOfString:f];
        if (range.location == NSNotFound)
        {
            name = [name substringToIndex:colon.location];
        }
        else
        {
            name = [name substringFromIndex:f.length];
        }
    }
    return name;
}

-(BOOL) isMultiIce
{
    BOOL en = [self.subtypes containsObject:@"Sentry"]
           && [self.subtypes containsObject:@"Barrier"]
           && [self.subtypes containsObject:@"Code Gate"];
    BOOL localized = [self.subtypes containsObject:l10n(@"Sentry")]
                  && [self.subtypes containsObject:l10n(@"Barrier")]
                  && [self.subtypes containsObject:l10n(@"Code Gate")];
    return en || localized;
}

-(void) setAlliance:(NSString *)subtype
{
    if (subtype.length > 0) {
        NSRange range = [subtype rangeOfString:@"Alliance" options:NSCaseInsensitiveSearch];
        self->_isAlliance = range.location != NSNotFound;
    }
}

-(void) setVirtual:(NSString*)subtype
{
    if (subtype.length > 0) {
        NSRange range = [subtype rangeOfString:@"Virtual" options:NSCaseInsensitiveSearch];
        self->_isVirtual = range.location != NSNotFound;
    }
}

-(BOOL) isValid
{
    return self.code.length > 0 && self.name.length > 0 && self.faction != NRFactionNone && self.role != NRRoleNone;
}

#pragma mark nsobject

-(BOOL) isEqual:(id)object
{
    Card* other = (Card*)object;
    return [self.code isEqualToString:other.code];
}

- (NSUInteger)hash
{
    return self.code.hash;
}

@end