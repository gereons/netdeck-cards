//
//  CardEditorViewController.m
//  NRDB
//
//  Created by Gereon Steffens on 09.12.13.
//  Copyright (c) 2014 Gereon Steffens. All rights reserved.
//

#import "CardEditorViewController.h"
#import "CardData.h"

@interface CardEditorViewController ()

@property CardData* card;
@property UIButton* clearButton;
@property UIButton* saveButton;
@property UIButton* deleteButton;
@property UIButton* loadAllButton;

@end

@implementation CardEditorViewController

enum { DELETE_CARD_TAG, LOAD_ALL_TAG };

static NSMutableArray* labels;
static NSMutableArray* attrs;
static NSMutableArray* types;

struct cardField {
    char* attr;
    char* label;
    FieldType type;
};

static struct cardField cardFields[] = {
    { "code", "Card Code", StringField },
    { "name", "Card Name", StringField },
    { "text", "Card Text", StringField },
    { "flavor", "Flavor Text", StringField },
    { "factionStr", "Faction", StringField },
    { "roleStr", "Role", StringField },
    { "typeStr", "Type", StringField },
    { "subtype", "Subtypes", StringField },
    { "setName", "Set Name", StringField },
    { "number", "Card number in Set", IntField },
    { "quantity", "Quantity in Set", IntField },
    { "unique", "Unique?", BooleanField },
    { "influenceLimit", "Influence Limit", IntField },
    { "minimumDecksize", "Minimum Deck Size", IntField },
    { "baselink", "Base Link", IntField },
    { "advancementCost", "Advancement Cost", IntField },
    { "agendaPoints", "Agenda Points", IntField },
    { "strength", "Strength", IntField },
    { "mu", "Memory Units", IntField },
    { "cost", "Cost", IntField },
    { "trash", "Trash Cost", IntField },
    { "influence", "Influence", IntField },
    { "url", "URL", StringField },
    { "imageSrc", "Image URL", StringField },
    { "artist", "Artist", StringField },
    { 0 }
};

+(void) initialize
{
    labels = [NSMutableArray array];
    attrs = [NSMutableArray array];
    types = [NSMutableArray array];
    
    struct cardField* field = cardFields;
    while (field->attr)
    {
        [attrs addObject:[NSString stringWithUTF8String:field->attr]];
        [labels addObject:[NSString stringWithUTF8String:field->label]];
        [types addObject:@(field->type)];
        ++field;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

-(void) viewDidLoad
{
    self.navigationController.navigationBar.topItem.title = @"Card Editor";
}

#pragma mark Search Bar

-(void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"cancel search");
    
    [searchBar resignFirstResponder];
}

-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    NSLog(@"do search %@", searchBar.text);
    
    self.card = [CardData cardByCode:searchBar.text];
    if (self.card == nil)
    {
        NSString* msg = [NSString stringWithFormat:@"Card Code %@ not found.", searchBar.text];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Nil message:msg delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        self.clearButton.enabled = YES;
        self.saveButton.enabled = YES;
        self.deleteButton.enabled = YES;
        [self.tableView reloadData];
    }
}

#pragma mark Header Buttons

-(void) clearData:(id)sender
{
    self.card = nil;
    [self.tableView reloadData];
}

-(void) saveData:(id)sender
{
    NSAssert(self.card != nil, @"no card");
    
    [self.card synthesizeMissingFields];
    if (self.card.isValid)
    {
        // [CardData archiveData];
    }
}

-(void) deleteData:(id) sender
{
    if (self.card != nil)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Nil message:@"Really delete this card?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alert.tag = DELETE_CARD_TAG;
        [alert show];
    }
}

-(void) loadData:(id) sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Nil message:@"Load card data from NetrunnerDB.com?\nThis will replace all current cards." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.tag = LOAD_ALL_TAG;
    [alert show];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        if (alertView.tag == DELETE_CARD_TAG)
        {
            [CardData deleteCard:self.card];
            // [CardData archiveData];
        }
        else if (alertView.tag == LOAD_ALL_TAG)
        {
            [CardData setupFromNetrunnerDbApi];
        }
        self.card = nil;
        [self.tableView reloadData];
    }
}

#pragma mark Table View

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 704, 100)];
    
    UISearchBar* search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 704, 50)];
    search.placeholder = @"Search for Card Code";
    search.autocorrectionType = UITextAutocorrectionTypeNo;
    search.showsCancelButton = YES;
    search.showsScopeBar = YES;
    search.delegate = self;
    [header addSubview:search];

    CGRect sepFrame = CGRectMake(0, 99, 704, 1);
    UIView* separatorView = [[UIView alloc] initWithFrame:sepFrame];
    separatorView.backgroundColor = [UIColor lightGrayColor];
    [header addSubview:separatorView];
    
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.clearButton.frame = CGRectMake(10, 55, 50, 40);
    [self.clearButton addTarget:self action:@selector(clearData:) forControlEvents:UIControlEventTouchUpInside];
    [self.clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    self.clearButton.enabled = self.card != nil;
    [header addSubview:self.clearButton];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveButton.frame = CGRectMake(70, 55, 50, 40);
    [self.saveButton addTarget:self action:@selector(saveData:) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    self.saveButton.enabled = self.card != nil;
    [header addSubview:self.saveButton];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteButton.frame = CGRectMake(130, 55, 50, 40);
    [self.deleteButton addTarget:self action:@selector(deleteData:) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    self.deleteButton.enabled = self.card != nil;
    [header addSubview:self.deleteButton];
    
    self.loadAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loadAllButton.frame = CGRectMake(600, 55, 100, 40);
    [self.loadAllButton addTarget:self action:@selector(loadData:) forControlEvents:UIControlEventTouchUpInside];
    [self.loadAllButton setTitle:@"Load Cards" forState:UIControlStateNormal];
    
    [header addSubview:self.loadAllButton];

    header.backgroundColor = [UIColor whiteColor];
    
    return header;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100.0;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return labels.count;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"editCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSInteger row = indexPath.row;
    
    UIView* subView;
    FieldType type = [[types objectAtIndex:row] intValue];
    if (type == BooleanField)
    {
        UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectMake(200, 5, 30, 30)];
        [sw addTarget:self action:@selector(switchToggle:) forControlEvents:UIControlEventValueChanged];
        subView = sw;
    }
    else
    {
        UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(200, 5, 450, 30)];
        tf.borderStyle = UITextBorderStyleRoundedRect;
        tf.keyboardType = type == StringField ? UIKeyboardTypeDefault : UIKeyboardTypeNumberPad;
        tf.returnKeyType = UIReturnKeyDone;
        tf.delegate = self;
        
        if (self.card)
        {
            if (type == StringField)
            {
                tf.text = [self.card valueForKey:[attrs objectAtIndex:row]];
            }
            else
            {
                NSNumber* n = [self.card valueForKey:[attrs objectAtIndex:row]];
                tf.text = [n stringValue];
            }
        }
        subView = tf;
    }
    subView.tag = row;
    [cell.contentView addSubview:subView];
    
    cell.textLabel.text = [labels objectAtIndex:row];
    return cell;
}

-(void) switchToggle:(UISwitch*)sender
{
    NSInteger row = sender.tag;
    NSString* attr = [attrs objectAtIndex:row];
    NSLog(@"bool change: %@ = %d", attr, sender.on);
    
    [self setCardValue:@(sender.on) forKey:attr];
}

-(void) textFieldDidEndEditing:(UITextField *)textField
{
    NSInteger row = textField.tag;
    NSString* attr = [attrs objectAtIndex:row];
    FieldType type = [[types objectAtIndex:row] intValue];
    
    if (type == StringField)
    {
        NSLog(@"text change: %@ = %@", attr, textField.text);
        
        [self setCardValue:textField.text forKey:attr];
    }
    else
    {
        int value = [textField.text intValue];
        NSLog(@"int change: %@ = %d", attr, value);
        
        [self setCardValue:@(value) forKey:attr];
    }
}

-(void) setCardValue:(id)value forKey:(NSString *)key
{
    if (self.card == nil)
    {
        self.card = [CardData new];
    }
    
    if (self.card.code.length > 0)
    {
        self.clearButton.enabled = YES;
        self.saveButton.enabled = YES;
        self.deleteButton.enabled = YES;
    }
    [self.card setValue:value forKey:key];
}


@end
