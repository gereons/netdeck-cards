//
//  Card.m
//  NRDB
//
//  Created by Gereon Steffens on 24.11.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "Card.h"
#import "CardManager.h"
#import "CardType.h"
#import "Faction.h"

#import <DTCoreText.h>

@interface Card()

@property NSAttributedString* attributedText;

@property NSString* roleStr;
@property NSString* setCode;
@property NSString* smallImageSrc;
@property NSString* largeImageSrc;
@property NSString* lastModified;

@end

@implementation Card

static NSDictionary* roleCodes;
static NSArray* max1InDeck;
static NSArray* specialIds;
static NSArray* draftIds;
static NSDictionary* coreTextOptions;
static NSDictionary* factionColors;
static NSDictionary* cropValues;
static BOOL isRetina;

+(void) initialize
{
    max1InDeck = @[ DIRECTOR_HAAS_PET_PROJ, PHILOTIC_ENTANGLEMENT,
                    UTOPIA_SHARD, UTOPIA_FRAGMENT,
                    HADES_SHARD, HADES_FRAGMENT,
                    EDEN_SHARD, EDEN_FRAGMENT ];
    
    draftIds = @[ THE_SHADOW, THE_MASQUE ];
    specialIds = @[ LARAMY_FISK, THE_COLLECTIVE, CHRONOS_PROTOCOL_HB, CHRONOS_PROTOCOL_JIN ];
    
    roleCodes = @{ @"runner": @(NRRoleRunner), @"corp": @(NRRoleCorp) };
    
    coreTextOptions = @{
                     DTUseiOS6Attributes: @(YES),
                     DTDefaultFontFamily: @"Helvetica",
                     DTDefaultFontSize: @(13)
    };
    
    isRetina = [UIScreen mainScreen].scale == 2.0;
   
    factionColors = @{
                      @(NRFactionJinteki):      @(0xc62026),
                      @(NRFactionNBN):          @(0xd7a32d),
                      @(NRFactionWeyland):      @(0x2d7868),
                      @(NRFactionHaasBioroid):  @(0x6b2b8a),
                      @(NRFactionShaper):       @(0x6ab545),
                      @(NRFactionCriminal):     @(0x4f67b0),
                      @(NRFactionAnarch):       @(0xf47c28)
    };
    
    cropValues = @{
                   @(NRCardTypeAgenda): @15,
                   @(NRCardTypeAsset): @20,
                   @(NRCardTypeEvent): @10,
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
    return [NSString stringWithFormat:@"bc0f047c-01b1-427f-a439-d451eda%@", self.code];
}

-(Card*) altCard
{
    return [CardManager altCardFor:self.code];
}

-(NSUInteger) factionHexColor
{
    NSNumber*n = factionColors[@(self.faction)];
    return [n unsignedIntegerValue];
}

-(UIColor*) factionColor
{
    NSUInteger rgb = [self factionHexColor];
    return UIColorFromRGB(rgb);
}

-(int) cropY
{
    NSNumber*n = cropValues[@(self.type)];
    return [n intValue];
}

-(NSString*) name_en
{
    return self->_name_en ? self->_name_en : self->_name;
}

-(NSString*) imageSrc
{
    if (isRetina && self.largeImageSrc)
    {
        return self.largeImageSrc;
    }
    else
    {
        return self.smallImageSrc;
    }
}


#pragma mark from json

#define JSON_INT(key, attr)          do { NSString*tmp = [json objectForKey:attr]; c->_##key = tmp ? [tmp intValue] : -1; } while (0)
#define JSON_BOOL(key, attr)         c->_##key = [[json objectForKey:attr] boolValue]
#define JSON_STR(key, attr)          c->_##key = [json objectForKey:attr]

+(Card*) cardFromJson:(NSDictionary*)json
{
    Card* c = [Card new];
    
    JSON_STR(code, @"code");
    JSON_STR(name, @"title");
    JSON_STR(text, @"text");
    JSON_STR(flavor, @"flavor");
    JSON_STR(factionStr, @"faction");
    NSString* factionCode = [json objectForKey:@"faction_code"];
    c->_faction = [Faction faction:factionCode];
    NSAssert(c.faction != NRFactionNone, @"no faction for %@", c.code);
    
    JSON_STR(roleStr, @"side");
    NSString* roleCode = [json objectForKey:@"side_code"];
    c->_role = [[roleCodes objectForKey:roleCode] integerValue];
    NSAssert(c.role != NRRoleNone, @"no role for %@", c.code);

    JSON_STR(typeStr, @"type");
    NSString* typeCode = [json objectForKey:@"type_code"];
    c->_type = [CardType type:typeCode];
    NSAssert(c.type != NRCardTypeNone, @"no type for %@", c.code);
    
    JSON_STR(setName, @"setname");
    JSON_STR(setCode, @"set_code");
    if ([draftIds containsObject:c.code])
    {
        c.setCode = @"draft";
    }
    
    JSON_STR(subtype, @"subtype");
    if (c.subtype.length == 0)
    {
        c->_subtype = nil;
    }
    if (c.subtype && c.type != NRCardTypeIdentity)
    {
        c->_subtypes = [c.subtype componentsSeparatedByString:@" - "];
    }
    
    JSON_STR(subtypeCode, @"subtype_code");
    if (c.subtypeCode.length == 0)
    {
        c->_subtypeCode = nil;
    }
    if (c.subtypeCode && c.type != NRCardTypeIdentity)
    {
        c->_subtypeCodes = [c.subtypeCode componentsSeparatedByString:@" - "];
    }
    
    JSON_INT(number, @"number");
    JSON_INT(quantity, @"quantity");
    JSON_BOOL(unique, @"uniqueness");
    JSON_BOOL(limited, @"limited");
    JSON_INT(influenceLimit, @"influencelimit");
    JSON_INT(minimumDecksize, @"minimumdecksize");
    JSON_INT(baseLink, @"baselink");
    JSON_INT(advancementCost, @"advancementcost");
    JSON_INT(agendaPoints, @"agendapoints");
    JSON_INT(mu, @"memoryunits");
    JSON_INT(strength, @"strength");
    JSON_INT(cost, @"cost");
    JSON_INT(influence, @"factioncost");
    JSON_INT(trash, @"trash");
    
    JSON_STR(url, @"url");
    JSON_STR(smallImageSrc, @"imagesrc");
    if (c.smallImageSrc.length == 0)
    {
        c.smallImageSrc = nil;
    }
    JSON_STR(largeImageSrc, @"largeimagesrc");
    if (c.largeImageSrc.length == 0)
    {
        c.largeImageSrc = nil;
    }
            
    JSON_STR(artist, @"illustrator");
    c->_lastModified = [json objectForKey:@"last-modified"];
    
    c->_maxCopies = 3;
    if ([max1InDeck containsObject:c.code] || c.limited || c.type == NRCardTypeIdentity)
    {
        c->_maxCopies = 1;
    }
    
    return c;
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