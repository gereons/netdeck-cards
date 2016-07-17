//
//  DeckListViewController.m
//  Net Deck
//
//  Created by Gereon Steffens on 08.12.13.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@import SVProgressHUD;

#import "DeckListViewController.h"
#import "CardImageViewPopover.h"
#import "IdentitySelectionViewController.h"
#import "DeckAnalysisViewController.h"
#import "DeckNotesPopup.h"
#import "DeckHistoryPopup.h"
#import "CardImagePopup.h"

#import "CardCell.h"
#import "CardImageCell.h"
#import "CGRectUtils.h"

@interface DeckListViewController ()

@property NSArray<NSString*>* sections;
@property NSArray<NSArray<CardCounter*>*>* cards;

@property UIAlertController* actionSheet;
@property UIPrintInteractionController* printController;
@property UIBarButtonItem* toggleViewButton;
@property UIBarButtonItem* saveButton;
@property UIBarButtonItem* exportButton;
@property UIBarButtonItem* stateButton;
@property UIBarButtonItem* nrdbButton;
@property UIProgressView* progressView;

@property NSString* filename;
@property BOOL autoSave;
@property BOOL autoSaveDropbox;
@property BOOL useNetrunnerdb;
@property BOOL autoSaveNRDB;

@property NRDeckSort sortType;
@property CGFloat scale;
@property BOOL largeCells;

@property BOOL initializing;
@property NSTimer* historyTimer;
@property NSInteger historyTicker;

@end

#define HISTORY_SAVE_INTERVAL   60

@implementation DeckListViewController

- (void) dealloc
{
    NSAssert(self.collectionView.window == nil, @"collectionView.window still set");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    self.collectionView = nil;
    
    [self stopHistoryTimer:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.initializing = YES;
    
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    self.useNetrunnerdb = [settings boolForKey:SettingsKeys.USE_NRDB];
    self.autoSaveNRDB = self.useNetrunnerdb && [settings boolForKey:SettingsKeys.NRDB_AUTOSAVE];
    self.sortType = [settings integerForKey:SettingsKeys.DECK_VIEW_SORT];
    
    CGFloat scale = [settings floatForKey:SettingsKeys.DECK_VIEW_SCALE];
    self.scale = scale == 0 ? 1.0 : scale;
    
    if (self.filename)
    {
        self.deck = [DeckManager loadDeckFromPath:self.filename];
        NSAssert(self.role == self.deck.role, @"role mismatch");
        self.deckNameLabel.text = self.deck.name;
    }
    
    if (self.deck == nil)
    {
        self.deck = [[Deck alloc] init];
        self.deck.role = self.role;
    }
    
    if (self.deck.filename == nil)
    {
        if (self.deck.name == nil)
        {
            NSInteger seq = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.FILE_SEQ] + 1;
            self.deck.name = [NSString stringWithFormat:@"Deck #%ld", (long)seq];
        }
        self.deckNameLabel.text = self.deck.name;
    }
    
    [self initCards];
    
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[ImageCache hexTile]];
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"LargeCardCell" bundle:nil] forCellReuseIdentifier:@"largeCardCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SmallCardCell" bundle:nil] forCellReuseIdentifier:@"smallCardCell"];

    self.largeCells = YES;
    
    UIView* footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    UINavigationItem* topItem = self.navigationController.navigationBar.topItem;
    
    // left buttons
    NSArray* selections = @[
        [UIImage imageNamed:@"deckview_card"],   // NRCardViewImage
        [UIImage imageNamed:@"deckview_table"],  // NRCardViewLargeTable
        [UIImage imageNamed:@"deckview_list"]    // NRCardViewSmallTable
    ];
    UISegmentedControl* viewSelector = [[UISegmentedControl alloc] initWithItems:selections];
    viewSelector.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:SettingsKeys.DECK_VIEW_STYLE];
    [viewSelector addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventValueChanged];
    self.toggleViewButton = [[UIBarButtonItem alloc] initWithCustomView:viewSelector];
    [self doToggleView:viewSelector.selectedSegmentIndex];
    
    topItem.leftBarButtonItems = @[
        self.toggleViewButton,
    ];
    
    self.autoSave = [settings boolForKey:SettingsKeys.AUTO_SAVE];
    self.autoSaveDropbox = self.autoSave && [settings boolForKey:SettingsKeys.USE_DROPBOX] && [settings boolForKey:SettingsKeys.AUTO_SAVE_DB];
    
    // right buttons
    self.exportButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"702-share"] style:UIBarButtonItemStylePlain target:self action:@selector(exportDeck:)];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Save") style:UIBarButtonItemStylePlain target:self action:@selector(saveDeckClicked:)];
    self.saveButton.enabled = NO;
    
    UIImage* img = [[UIImage imageNamed:@"netrunnerdb_com"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.nrdbButton = [[UIBarButtonItem alloc] initWithImage:img style:UIBarButtonItemStylePlain target:self action:@selector(nrdbButtonClicked:)];
    
    self.stateButton = [[UIBarButtonItem alloc] initWithTitle:[DeckState buttonLabelFor:self.deck.state] style:UIBarButtonItemStylePlain target:self action:@selector(changeState:)];
    self.stateButton.possibleTitles = [NSSet setWithArray:@[
                                                            [DeckState buttonLabelFor:NRDeckStateNone],
                                                            [DeckState buttonLabelFor:NRDeckStateActive],
                                                            [DeckState buttonLabelFor:NRDeckStateTesting],
                                                            [DeckState buttonLabelFor:NRDeckStateRetired],
                                                            ]];
    
    UIBarButtonItem* dupButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Duplicate") style:UIBarButtonItemStylePlain target:self action:@selector(duplicateDeck:)];
    UIBarButtonItem* nameButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Name") style:UIBarButtonItemStylePlain target:self action:@selector(enterName:)];
    UIBarButtonItem* sortButton = [[UIBarButtonItem alloc] initWithTitle:l10n(@"Sort") style:UIBarButtonItemStylePlain target:self action:@selector(sortPopup:)];
    
    // add from right to left!
    NSMutableArray* rightButtons = [NSMutableArray array];
    [rightButtons addObject:self.exportButton];
    [rightButtons addObject:sortButton];
    [rightButtons addObject:dupButton];
    if (self.useNetrunnerdb)
    {
        [rightButtons addObject:self.nrdbButton];
    }
    if (!self.autoSave)
    {
        [rightButtons addObject:self.saveButton];
    }
    [rightButtons addObject:nameButton];
    [rightButtons addObject:self.stateButton];
    
    topItem.rightBarButtonItems = rightButtons;

    // set up bottom toolbar
    [self.drawButton setTitle:l10n(@"Draw") forState:UIControlStateNormal];
    [self.analysisButton setTitle:l10n(@"Analysis") forState:UIControlStateNormal];
    [self.notesButton setTitle:l10n(@"Notes") forState:UIControlStateNormal];
    [self.historyButton setTitle:l10n(@"History") forState:UIControlStateNormal];
    self.historyButton.enabled = self.deck.filename != nil && self.deck.revisions.count > 0;
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(identitySelected:) name:Notifications.SELECT_IDENTITY object:nil];
    [nc addObserver:self selector:@selector(deckChanged:) name:Notifications.DECK_CHANGED object:nil];
    [nc addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(notesChanged:) name:Notifications.NOTES_CHANGED object:nil];
    
    [nc addObserver:self selector:@selector(stopHistoryTimer:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(startHistoryTimer:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.deckNameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterName:)]];
    self.deckNameLabel.userInteractionEnabled = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardImageCell" bundle:nil] forCellWithReuseIdentifier:@"cardImageCell"];
    
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.collectionView addGestureRecognizer:pinch];
    
    self.footerLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(statusTapped:)];
    [self.footerLabel addGestureRecognizer:tap];
    self.footerLabel.userInteractionEnabled = YES;
    
    [self.mwlButton addTarget:self action:@selector(mwlTapped:) forControlEvents:UIControlEventTouchUpInside];

    [self refresh];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.deck.cards.count > 0 || self.deck.identity != nil)
    {
        // so that CardFilterViewController gets a chance to reload
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:nil userInfo:@{@"initialLoad": @(YES)}];
    }
    self.initializing = NO;
    
    if (self.deck.identity == nil && self.filename == nil && self.deck.cards.count == 0)
    {
        [self selectIdentity:nil];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.AUTO_HISTORY])
    {
        int x = self.view.center.x - HISTORY_SAVE_INTERVAL;
        int width = 2 * HISTORY_SAVE_INTERVAL; // self.analysisButton.frame.origin.x + self.analysisButton.frame.size.width - x;
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(x, 40, width, 3)];
        self.progressView.progress = 1.0;
        self.progressView.progressTintColor = [UIColor darkGrayColor];
        [self.toolBar addSubview:self.progressView];
    }
    
    if (self.deck.filename)
    {
        [self startHistoryTimer:nil];
    }
    else
    {
        self.progressView.hidden = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:@(self.scale) forKey:SettingsKeys.DECK_VIEW_SCALE];
    [settings setObject:@(self.sortType) forKey:SettingsKeys.DECK_VIEW_SORT];

    [self stopHistoryTimer:nil];
}

-(void) setDeck:(Deck *)deck
{
    BOOL overwriting = self->_deck != nil;
    self->_deck = deck;
    if (overwriting) {
        [self refresh];
    }
}

#pragma mark history timer

-(void) startHistoryTimer:(id)notification
{
    // stop existing timer, if any
    [self stopHistoryTimer:notification];

    BOOL autoHistory = [[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.AUTO_HISTORY];
    if (autoHistory)
    {
        self.historyTimer = [NSTimer timerWithTimeInterval:1
                                                    target:self
                                                  selector:@selector(historySave:)
                                                  userInfo:nil
                                                   repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:self.historyTimer forMode:NSRunLoopCommonModes];
        
        self.progressView.progress = 1.0;
        self.historyTicker = HISTORY_SAVE_INTERVAL;
    }
}

-(void) stopHistoryTimer:(id)notification
{
    [self.historyTimer invalidate];
    self.historyTimer = nil;
    self.historyTicker = 0;
}

-(void) historySave:(id)timer
{
    --self.historyTicker;

    float progress = (float)self.historyTicker / (float)HISTORY_SAVE_INTERVAL;
    [self.progressView setProgress:progress animated:NO];
    if (self.historyTicker <= 0)
    {
        [self.deck mergeRevisions];
        self.historyButton.enabled = YES;
        self.historyTicker = HISTORY_SAVE_INTERVAL+1;
    }
}

#pragma mark keyboard show/hide

-(void) willShowKeyboard:(NSNotification*)sender
{
    float duration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect beginFrame = [[sender.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[sender.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float yDiff = beginFrame.origin.y - endFrame.origin.y;

    self.toolbarBottomMargin.constant = yDiff;
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void) willHideKeyboard:(NSNotification*)sender
{
    float duration = [[sender.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.toolbarBottomMargin.constant = 0;
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void) loadDeckFromFile:(NSString *)filename
{
    self.filename = filename;
}

-(void) saveDeckClicked:(id)sender
{
    [self saveDeckManually:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_SAVED object:nil];
}

-(void) saveDeckManually:(BOOL)manually
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    if (manually)
    {
        [self stopHistoryTimer:nil];
        self.historyButton.enabled = YES;
        self.progressView.hidden = NO;
        [self startHistoryTimer:nil];
        
        [self.deck mergeRevisions];
        [SVProgressHUD showSuccessWithStatus:l10n(@"Saving...")];
    }
    
    BOOL keepLastModified = !manually;
    if (self.autoSave) {
        keepLastModified = NO;
    }
    if (keepLastModified) {
        [self.deck updateOnDisk];
    } else {
        [self.deck saveToDisk];
    }
    
    if (manually && self.autoSaveNRDB)
    {
        [self saveDeckToNetrunnerDb];
    }
    
    self.saveButton.enabled = NO;
    
    if (self.autoSaveDropbox)
    {
        if (self.deck.identity && self.deck.cards.count > 0)
        {
            [DeckExport asOctgn:self.deck autoSave:YES];
        }
    }
}

-(void) analysisClicked:(id)sender
{
    [DeckAnalysisViewController showForDeck:self.deck inViewController:self];
}

-(void) drawSimulatorClicked:(id)sender
{
    [DrawSimulatorViewController showForDeck:self.deck inViewController:self];
}

-(void) nrdbButtonClicked:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    if (self.deck.netrunnerDbId.length == 0)
    {
        NSString* msg = l10n(@"This deck is not (yet) linked to a deck on NetrunnerDB.com");
        UIAlertController* alert = [UIAlertController alertWithTitle:nil
                                                                       message:msg];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Save") handler:^(UIAlertAction * action) {
            LOG_EVENT(@"Save to NRDB", nil);
            [self saveDeckToNetrunnerDb];
        }]];
        [alert show];
    }
    else
    {
        NSString* msg = [NSString stringWithFormat:l10n(@"This deck is linked to deck %@ on NetrunnerDB.com"), self.deck.netrunnerDbId ];
        UIAlertController* alert = [UIAlertController alertWithTitle:nil
                                                             message:msg];
        
        [alert addAction:[UIAlertAction cancelAlertAction:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Open in Safari") handler:^(UIAlertAction * action) {
            if (Reachability.online) {
                LOG_EVENT(@"Open in Safari", nil);
                [self openInSafari:self.deck];
            } else {
                [self showOfflineAlert];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Publish deck") handler:^(UIAlertAction * action) {
            if (Reachability.online) {
                LOG_EVENT(@"Publish Deck", nil);
                [self publishDeck:self.deck];
            } else {
                [self showOfflineAlert];
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Unlink") handler:^(UIAlertAction * action) {
            self.deck.netrunnerDbId = nil;
            if (self.autoSave)
            {
                LOG_EVENT(@"Unlink Deck", nil);
                [self saveDeckManually:NO];
            }
            [self refresh];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Reimport") handler:^(UIAlertAction * action) {
            LOG_EVENT(@"Reimport Deck", nil);
            [self reImportDeckFromNetrunnerDb];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Save") handler:^(UIAlertAction * action) {
            LOG_EVENT(@"Save to NRDB", nil);
            [self saveDeckToNetrunnerDb];
        }]];
        
        [alert show];
    }
}

-(void) saveDeckToNetrunnerDb
{
    if (!Reachability.online)
    {
        [self showOfflineAlert];
        return;
    }
    
    [SVProgressHUD showWithStatus:l10n(@"Saving Deck...")];
    
    [[NRDB sharedInstance] saveDeck:self.deck completion:^(BOOL ok, NSString* deckId, NSString* msg) {
        if (!ok)
        {
            [UIAlertController alertWithTitle:nil message:l10n(@"Saving the deck at NetrunnerDB.com failed.") button:l10n(@"OK")];
        }
        if (ok && deckId)
        {
            self.deck.netrunnerDbId = deckId;
            [self.deck updateOnDisk];
        }
        
        [SVProgressHUD dismiss];
    }];
}

-(void) reImportDeckFromNetrunnerDb
{
    if (!Reachability.online)
    {
        [self showOfflineAlert];
        return;
    }
    
    NSAssert(self.deck.netrunnerDbId != nil, @"no nrdb deck id");
    [SVProgressHUD showWithStatus:l10n(@"Loading Deck...")];
    
    [[NRDB sharedInstance] loadDeck:self.deck.netrunnerDbId completion:^(Deck* deck) {
        if (deck == nil) {
            [UIAlertController alertWithTitle:nil message:l10n(@"Loading the deck from NetrunnerDB.com failed.") button:l10n(@"OK")];
        } else {
            deck.filename = self.deck.filename;
            self.deck = deck;
            self.deck.state = self.deck.state; // force .modified=YES
            
            [self refresh];
        }
        
        [SVProgressHUD dismiss];
    }];
}

-(void) openInSafari:(Deck*)deck
{
    NSString* url = [NSString stringWithFormat:@"https://netrunnerdb.com/en/deck/view/%@", deck.netrunnerDbId ];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(void) publishDeck:(Deck*)deck
{
    NSArray* errors = [deck checkValidity];
    if (errors.count == 0)
    {
        [SVProgressHUD showWithStatus:l10n(@"Publishing Deck...")];

        [[NRDB sharedInstance] publishDeck:deck completion:^(BOOL ok, NSString *deckId, NSString* errorMsg) {
            [SVProgressHUD dismiss];
            if (!ok)
            {
                NSString* failed = l10n(@"Publishing the deck at NetrunnerDB.com failed.");
                if (errorMsg.length > 0) {
                    failed = [NSString stringWithFormat:@"%@\n'%@'", failed, errorMsg];
                }
                [UIAlertController alertWithTitle:nil message:failed button:l10n(@"OK")];
            }
            if (ok && deckId)
            {
                NSString* msg = [NSString stringWithFormat:l10n(@"Deck published with ID %@"), deckId];
                [UIAlertController alertWithTitle:nil message:msg button:l10n(@"OK")];
            }
        }];
    }
    else
    {
        [UIAlertController alertWithTitle:nil message:l10n(@"Only valid decks can be published.") button:l10n(@"OK")];
    }
}

-(void) showOfflineAlert
{
    [UIAlertController alertWithTitle:nil
                         message:l10n(@"An Internet connection is required.")
                         button:l10n(@"OK")];
}

-(void) notesButtonClicked:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    [DeckNotesPopup showForDeck:self.deck inViewController:self];
}

-(void) historyButtonClicked:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    [self.deck mergeRevisions];
    [DeckHistoryPopup showForDeck:self.deck inViewController:self];
}

#pragma mark duplicate deck

-(void) duplicateDeck:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    UIAlertController* alert = [UIAlertController alertWithTitle:nil message:l10n(@"Duplicate this deck?")];
    
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"No") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Yes, switch to copy") handler:^(UIAlertAction * action) {
        Deck* newDeck = [self.deck duplicate];
        self.deck = newDeck;
        if (self.autoSave)
        {
            [self.deck saveToDisk];
        }
        else
        {
            self.deck.state = self.deck.state; // force .modified=YES
        }
        [self refresh];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:l10n(@"Yes, but stay here") handler:^(UIAlertAction * action) {
        Deck* newDeck = [self.deck duplicate];
        [newDeck saveToDisk];
        if (self.autoSaveDropbox)
        {
            if (newDeck.identity && newDeck.cards.count > 0)
            {
                [DeckExport asOctgn:newDeck autoSave:YES];
            }
        }
    }]];
    
    [alert show];
}

#pragma mark deck state

-(void) changeState:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    self.actionSheet = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Active"), self.deck.state == NRDeckStateActive)
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckState:NRDeckStateActive];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Testing"), self.deck.state == NRDeckStateTesting)
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckState:NRDeckStateTesting];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Retired"), self.deck.state == NRDeckStateRetired)
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckState:NRDeckStateRetired];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
                                                           self.actionSheet = nil;
                                                       }]];
    
    UIPopoverPresentationController* popover = self.actionSheet.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self.actionSheet.view layoutIfNeeded];
    
    [self presentViewController:self.actionSheet animated:NO completion:nil];
}

-(void) changeDeckState:(NRDeckState)newState
{
    NRDeckState oldState = self.deck.state;

    LOG_EVENT(@"Change State", (@{ @"From": [DeckState rawLabelFor:oldState], @"To": [DeckState rawLabelFor:newState]}) );
    self.deck.state = newState;
    [self.stateButton setTitle:[DeckState buttonLabelFor:self.deck.state]];
    if (self.deck.state != oldState)
    {
        if (self.autoSave)
        {
            [self saveDeckManually:NO];
        }
        [self refresh];
    }
    self.actionSheet = nil;
}

#pragma mark deck name

-(void) enterName:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    UIAlertController* nameAlert = [UIAlertController alertWithTitle:l10n(@"Enter Name")
                                                         message:nil];
    
    [nameAlert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.placeholder = l10n(@"Deck Name");
        textField.text = self.deck.name;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.returnKeyType = UIReturnKeyDone;
    }];
    
    [nameAlert addAction:[UIAlertAction cancelAlertAction:nil]];
    [nameAlert addAction:[UIAlertAction actionWithTitle:l10n(@"OK") handler:^(UIAlertAction * action) {
        self.deck.name = nameAlert.textFields[0].text;
        self.deckNameLabel.text = self.deck.name;
        if (self.autoSave)
        {
            [self saveDeckManually:NO];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:nil];
        }
        [self refresh];
    }]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.NAME_ALERT object:nil];
    [nameAlert show];
}

#pragma mark identity selection

-(void) selectIdentity:(id)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    
    Card* identity = self.deck.identity;
    [IdentitySelectionViewController showForRole:self.role inViewController:self withIdentity:identity];
}

-(void) identitySelected:(NSNotification*)sender
{
    NSString* code = [sender.userInfo objectForKey:@"code"];
    Card* card = [CardManager cardByCode:code];
    if (card)
    {
        NSAssert(card.role == self.deck.role, @"role mismatch");
    }
    
    if (card && ![self.deck.identity isEqual:card])
    {
        [self.deck addCard:card copies:1];
        [self refresh];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:nil];
    }
}

#pragma mark sort

-(void) sortPopup:(UIBarButtonItem*)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    if (self.printController)
    {
        [self dismissPrintController];
        return;
    }
    
    self.actionSheet = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Type"), self.sortType == NRDeckSortByType)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckSort:NRDeckSortByType];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Faction"), self.sortType == NRDeckSortByFactionType)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckSort:NRDeckSortByFactionType];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Set/Type"), self.sortType == NRDeckSortBySetType)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckSort:NRDeckSortBySetType];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"by Set/Number"), self.sortType == NRDeckSortBySetNum)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [self changeDeckSort:NRDeckSortBySetNum];
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
                                                           self.actionSheet = nil;
                                                       }]];
    
    UIPopoverPresentationController* popover = self.actionSheet.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self.actionSheet.view layoutIfNeeded];
    
    [self presentViewController:self.actionSheet animated:NO completion:nil];
}

-(void) changeDeckSort:(NRDeckSort)sortType
{
    self.sortType = sortType;
    self.actionSheet = nil;
    [self refresh];
}

#pragma mark export

-(void) exportDeck:(UIBarButtonItem*)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
        return;
    }
    if (self.printController)
    {
        [self dismissPrintController];
        return;
    }
    
    self.actionSheet = [UIAlertController actionSheetWithTitle:nil message:nil];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SettingsKeys.USE_DROPBOX])
    {
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Dropbox: OCTGN")
                                                           handler:^(UIAlertAction *action) {
                                                               LOG_EVENT(@"Export .o8d", nil);
                                                               [self octgnExport];
                                                           }]];
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Dropbox: BBCode")
                                                           handler:^(UIAlertAction *action) {
                                                               LOG_EVENT(@"Export BBCode", nil);
                                                               [DeckExport asBBCode:self.deck];
                                                               self.actionSheet = nil;
                                                           }]];
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Dropbox: Markdown")
                                                           handler:^(UIAlertAction *action) {
                                                               LOG_EVENT(@"Export MD", nil);
                                                               [DeckExport asMarkdown:self.deck];
                                                               self.actionSheet = nil;
                                                           }]];
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Dropbox: Plain Text")
                                                           handler:^(UIAlertAction *action) {
                                                               LOG_EVENT(@"Export Text", nil);
                                                               [DeckExport asPlaintext:self.deck];
                                                               self.actionSheet = nil;
                                                           }]];
    }
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Clipboard: BBCode")
                                                       handler:^(UIAlertAction *action) {
                                                           LOG_EVENT(@"Clip BBCode", nil);
                                                           [UIPasteboard generalPasteboard].string = [DeckExport asBBCodeString:self.deck];
                                                           [DeckImport updateCount];
                                                           self.actionSheet = nil;
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Clipboard: Markdown")
                                                       handler:^(UIAlertAction *action) {
                                                           LOG_EVENT(@"Clip MD", nil);
                                                           [UIPasteboard generalPasteboard].string = [DeckExport asMarkdownString:self.deck];
                                                           [DeckImport updateCount];
                                                           self.actionSheet = nil;
                                                       }]];
    [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Clipboard: Plain Text")
                                                       handler:^(UIAlertAction *action) {
                                                           LOG_EVENT(@"Clip Text", nil);
                                                           [UIPasteboard generalPasteboard].string = [DeckExport asPlaintextString:self.deck];
                                                           [DeckImport updateCount];
                                                           self.actionSheet = nil;
                                                       }]];
    
    if ([DeckEmail canSendMail])
    {
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"As Email")
                                                       handler:^(UIAlertAction *action) {
                                                           LOG_EVENT(@"Email Deck", nil);
                                                           [DeckEmail emailDeck:self.deck fromViewController:self];
                                                           self.actionSheet = nil;
                                                       }]];
    }
    if ([UIPrintInteractionController isPrintingAvailable])
    {
        [self.actionSheet addAction:[UIAlertAction actionWithTitle:l10n(@"Print")
                                                           handler:^(UIAlertAction *action) {
                                                               LOG_EVENT(@"Print Deck", nil);
                                                               [self printDeck:self.exportButton];
                                                               self.actionSheet = nil;
                                                           }]];
    }
    [self.actionSheet addAction:[UIAlertAction cancelAction:^(UIAlertAction *action) {
                                                           self.actionSheet = nil;
                                                       }]];
    
    UIPopoverPresentationController* popover = self.actionSheet.popoverPresentationController;
    popover.barButtonItem = sender;
    popover.sourceView = self.view;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [self.actionSheet.view layoutIfNeeded];
    
    [self presentViewController:self.actionSheet animated:NO completion:nil];
}

-(void) dismissActionSheet
{
    [self.actionSheet dismissViewControllerAnimated:NO completion:nil];
    self.actionSheet = nil;
}

-(void) octgnExport
{
    if (self.deck.identity == nil)
    {
        [UIAlertController alertWithTitle:nil message:l10n(@"Deck needs to have an Identity.") button:l10n(@"OK")];
        return;
    }
    if (self.deck.cards.count == 0)
    {
        [UIAlertController alertWithTitle:nil message:l10n(@"Deck needs to have Cards.") button:l10n(@"OK")];
        return;
    }
    [DeckExport asOctgn:self.deck autoSave:NO];
    self.actionSheet = nil;
}

#pragma mark toggle view

-(void) toggleView:(UISegmentedControl*)sender
{
    if (self.actionSheet)
    {
        [self dismissActionSheet];
    }

    NSInteger viewMode = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:viewMode forKey:SettingsKeys.DECK_VIEW_STYLE];
    [self doToggleView:viewMode];
}

-(void) doToggleView:(NSInteger)viewMode
{
    self.tableView.hidden = viewMode == NRCardViewImage;
    self.collectionView.hidden = viewMode != NRCardViewImage;
    
    self.largeCells = viewMode == NRCardViewLargeTable;
    
    [self reloadViews];
}

#pragma mark reload

-(void) reloadViews
{
    if (self.initializing)
    {
        return;
    }
    
    if (!self.tableView.hidden)
    {
        [self.tableView reloadData];
    }
    
    if (!self.collectionView.hidden)
    {
        [self.collectionView reloadData];
    }
}

#pragma mark notifications

-(void) notesChanged:(id)sender
{
    if (self.autoSave)
    {
        [self saveDeckManually:NO];
    }
    [self refresh];
}

-(void) deckChanged:(NSNotification*)sender
{
    BOOL initialLoad = [[sender.userInfo objectForKey:@"initialLoad"] boolValue];
    if (!initialLoad)
    {
        [self refresh];
    }
    
    if (self.autoSave && self.deck.modified)
    {
        [self saveDeckManually:NO];
    }
}

-(void) refresh
{
    [self initCards];
    [self reloadViews];
    
    self.saveButton.enabled = self.deck.modified;
    self.drawButton.enabled = self.deck.cards.count > 0;
    self.analysisButton.enabled = self.deck.cards.count > 0;
    
    NSMutableString* footer = [NSMutableString string];
    [footer appendString:[NSString stringWithFormat:@"%ld %@", (long)self.deck.size, self.deck.size == 1 ? l10n(@"Card") : l10n(@"Cards")]];
    if (self.deck.identity && !self.deck.isDraft)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld/%ld %@", (long)self.deck.influence, (long)self.deck.influenceLimit, l10n(@"Influence")]];
    }
    else
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.influence, l10n(@"Influence")]];
    }
    
    if (self.role == NRRoleCorp)
    {
        [footer appendString:[NSString stringWithFormat:@" · %ld %@", (long)self.deck.agendaPoints, l10n(@"AP")]];
    }
    
    NSArray* reasons = [self.deck checkValidity];
    if (reasons.count > 0)
    {
        [footer appendString:@" · "];
        [footer appendString:reasons[0]];
    }
    
    self.footerLabel.textColor = reasons.count == 0 ? [UIColor darkGrayColor] : [UIColor redColor];
    self.footerLabel.text = footer;
    
    NSString* set = [PackManager mostRecentPackUsedInDeck:self.deck];
    if (set)
    {
        self.lastSetLabel.text = [NSString stringWithFormat:l10n(@"Cards up to %@"), set];
    }
    else
    {
        self.lastSetLabel.text = @"";
    }
    
    self.deckNameLabel.text = self.deck.name;
}

-(void) initCards
{
    TableData* data = [self.deck dataForTableView:self.sortType];
    self.cards = data.values;
    self.sections = data.sections;
}

-(void) addCard:(Card *)card
{
    NSAssert(card != nil, @"add nil card?!?");
    [self.deck addCard:card copies:1];
    [self refresh];

    NSIndexPath* indexPath;
    int i=0;
    for (int section = 0; indexPath == nil && section < self.cards.count; ++section)
    {
        NSArray* arr = self.cards[section];
        for (int row = 0; row < arr.count; ++row)
        {
            CardCounter* cc = arr[row];
            
            if (!cc.isNull && [card isEqual:cc.card])
            {
                if (self.tableView.hidden)
                {
                    indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                }
                else
                {
                    indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                }
                break;
            }
            ++i;
        }
    }
    NSAssert(indexPath != nil, @"added card not found!?");
    
    if (!self.tableView.hidden)
    {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self performSelector:@selector(flashTableCell:) withObject:indexPath afterDelay:0.0];
    }
    if (!self.collectionView.hidden)
    {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        [self performSelector:@selector(flashImageCell:) withObject:indexPath afterDelay:0.0];
    }
    
    if (self.autoSave)
    {
        [self saveDeckManually:NO];
    }
}

-(void) flashTableCell:(NSIndexPath*)indexPath
{
    CardCell* cell = (CardCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^() {
                         cell.backgroundColor = [UIColor lightGrayColor];
                     }
                     completion:^(BOOL finished) {
                         cell.backgroundColor = [UIColor whiteColor];
                     }];

}

-(void) flashImageCell:(NSIndexPath*)indexPath
{
    CardImageCell* cell = (CardImageCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^() {
                         cell.transform = CGAffineTransformMakeScale(1.05, 1.05);
                     }
                     completion:^(BOOL finished) {
                         cell.transform = CGAffineTransformIdentity;
                     }];
}

#pragma mark Table View

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.largeCells ? 83 : 40;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView.hidden)
    {
        return 0;
    }
    return self.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* arr = self.cards[section];
    return arr.count;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* name = [self.sections objectAtIndex:section];
    NSArray* arr = self.cards[section];
    int cnt = 0;
    for (CardCounter* cc in arr)
    {
        if (!cc.isNull)
        {
            cnt += cc.count;
        }
    }
    
    if (section > 0 && cnt)
    {
        return [NSString stringWithFormat:@"%@ (%d)", name, cnt];
    }
    else
    {
        return name;
    }
}

- (CardCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = self.largeCells ? @"largeCardCell" : @"smallCardCell";
    CardCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.separatorInset = UIEdgeInsetsZero;
    
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    if (cc.isNull)
    {
        cc = nil;
    }
    
    cell.deck = self.deck;
    cell.cardCounter = cc;
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (cc != nil)
    {
        return !cc.isNull;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
        
        if (!cc.isNull)
        {
            [self.deck addCard:cc.card copies:0];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:nil];
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CardCounter* cc = [self.cards objectAtIndexPath:indexPath];
    
    if (!cc.isNull)
    {
        CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
        [CardImageViewPopover showForCard:cc.card fromRect:rect inViewController:self subView:self.tableView];
    }
}

-(NSString*) tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return l10n(@"Remove");
}

#pragma mark collectionview

#define CARD_WIDTH  225
#define CARD_HEIGHT 333

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((int)(CARD_WIDTH * self.scale), (int)(CARD_HEIGHT * self.scale));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 0, 2);
}


-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView.hidden)
    {
        return 0;
    }
    return 1;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1 + self.deck.cards.count;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    CardCounter* cc;
    if (index == 0)
    {
        if (self.deck.identity)
        {
            cc = self.deck.identityCc;
        }
    }
    else
    {
        --index;
        cc = self.deck.cards[index];
    }
    
    // NSLog(@"selected %@", cc.card.name);
    CardImageCell* cell = (CardImageCell*)[collectionView cellForItemAtIndexPath:indexPath];

    // convert to on-screen coordinates
    CGRect rect = [collectionView convertRect:cell.frame toView:collectionView.superview];

    BOOL topVisible = rect.origin.y >= 66;
    BOOL bottomVisible = rect.origin.y + rect.size.height <= 728;
    // NSLog(@"%@ %d %d", NSStringFromCGRect(rect), topVisible, bottomVisible);
    
    static const int POPUP_HEIGHT = 170; // full height (including the arrow) of the popup
    static const int LABEL_HEIGHT = 20; // height of the label underneath the image
    
    UIPopoverArrowDirection direction = UIPopoverArrowDirectionAny;

    CGRect popupOrigin = CGRectMake(cell.center.x, cell.frame.origin.y, 1, 1);
    if (topVisible && bottomVisible)
    {
        // fully visible, show from top of image
        direction = UIPopoverArrowDirectionUp;
    }
    else if (topVisible)
    {
        if (rect.origin.y < 728 - POPUP_HEIGHT)
        {
            // top Visible and enough space - show from top of image
            direction = UIPopoverArrowDirectionUp;
        }
        else
        {
            // top visible, not enough space - show above image
            direction = UIPopoverArrowDirectionDown;
        }
    }
    else if (bottomVisible)
    {
        popupOrigin.origin.y += cell.frame.size.height - LABEL_HEIGHT;
        if (rect.origin.y + rect.size.height >= 66 + POPUP_HEIGHT)
        {
            // bottom visible and enough space - show from bottom
            direction = UIPopoverArrowDirectionDown;
        }
        else
        {
            // bottom visible, not enough space - show below image
            direction = UIPopoverArrowDirectionUp;
        }
    }
    else
    {
        NSAssert(NO, @"selected invisible cell?!");
    }
    
    if (cc && cc.card.type != NRCardTypeIdentity)
    {
        CardImagePopup* cip = [CardImagePopup showForCard:cc inDeck:self.deck fromRect:popupOrigin inViewController:self subView:self.collectionView direction:direction];
        cip.cell = cell;
    }
    else
    {
        [self selectIdentity:nil];
    }
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellIdentifier = @"cardImageCell";
    
    CardImageCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[CardImageCell alloc] init];
    }
    
    NSInteger index = indexPath.row;
    CardCounter* cc;
    if (index == 0)
    {
        if (self.deck.identity)
        {
            cc = self.deck.identityCc;
        }
        cell.copiesLabel.text = @"";
    }
    else
    {
        --index;
        cc = self.deck.cards[index];
        
        if (cc.card.type == NRCardTypeAgenda)
        {
            cell.copiesLabel.text = [NSString stringWithFormat:@"×%lu · %lu AP", (unsigned long)cc.count, (unsigned long)(cc.count*cc.card.agendaPoints)];
        }
        else
        {
            NSUInteger influence = [self.deck influenceFor:cc];
            if (influence > 0)
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%lu · %lu %@", (unsigned long)cc.count, (unsigned long)influence, l10n(@"Influence")];
            }
            else
            {
                cell.copiesLabel.text = [NSString stringWithFormat:@"×%lu", (unsigned long)cc.count];
            }
        }
        
        cell.copiesLabel.textColor = [UIColor blackColor];
        if (!self.deck.isDraft && cc.card.owned < cc.count)
        {
            cell.copiesLabel.textColor = [UIColor redColor];
        }
    }
    
    if (![cell.cc.card isEqual:cc.card])
    {
        cell.image1.image = nil;
        cell.image2.image = nil;
        cell.image2.image = nil;
    }
    cell.cc = cc;
    
    if (cc.card)
    {
        [cell loadImage];
    }
    else
    {
        [cell setImageStack:[ImageCache placeholderFor:self.role]];
    }
    
    return cell;
}

-(void) pinchGesture:(UIPinchGestureRecognizer*)gesture
{
    static CGFloat scaleStart;
    static NSIndexPath* startIndex;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        scaleStart = self.scale;
        CGPoint startPoint = [gesture locationInView:self.collectionView];
        startIndex = [self.collectionView indexPathForItemAtPoint:startPoint];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        self.scale = scaleStart * gesture.scale;
    
        self.scale = MAX(self.scale, 0.5);
        self.scale = MIN(self.scale, 1.0);
    
        [self.collectionView reloadData];

        if (startIndex && startIndex.row < self.deck.cards.count)
        {
            [self.collectionView scrollToItemAtIndexPath:startIndex atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        startIndex = nil;
    }
}

#pragma mark printing

-(void) dismissPrintController
{
    [self.printController dismissAnimated:NO];
    self.printController = nil;
}

-(void) printDeck:(id)sender
{
    self.printController = [UIPrintInteractionController sharedPrintController];
    self.printController.delegate = self;
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = self.deck.name;
    self.printController.printInfo = printInfo;
    
    UISimpleTextPrintFormatter *formatter = [[UISimpleTextPrintFormatter alloc] initWithText:[DeckExport asPlaintextString:self.deck]];
    formatter.startPage = 0;
    formatter.contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0); // no margins
    formatter.font = [UIFont systemFontOfSize:10];
    self.printController.printFormatter = formatter;
    self.printController.showsPageRange = YES;
    
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
    ^(UIPrintInteractionController *printController, BOOL completed, NSError *error)
    {
        if (!completed && error)
        {
            // NSLog(@"Printing could not complete because of error: %@", error);
            NSString* msg = error.localizedDescription;
            [UIAlertController alertWithTitle:l10n(@"Printing Problem") message:msg button:l10n(@"OK")];
        }
    };
    
    [self.printController presentFromBarButtonItem:sender animated:NO completionHandler:completionHandler];
}

-(void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController
{
    self.printController = nil;
}

#pragma mark - MWL selection

-(void) mwlTapped:(id) sender {
    [self showMwlSelection];
}

-(void) statusTapped:(UITapGestureRecognizer*)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self showMwlSelection];
}

-(void) showMwlSelection {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:l10n(@"Deck Legality") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"Casual"), self.deck.mwl == NRMWLNone) handler:^(UIAlertAction * action) {
        [self setMwl:NRMWLNone];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"MWL v1.0"), self.deck.mwl == NRMWLv1_0) handler:^(UIAlertAction * action) {
        [self setMwl:NRMWLv1_0];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:CHECKED_TITLE(l10n(@"MWL v1.1"), self.deck.mwl == NRMWLv1_1) handler:^(UIAlertAction * action) {
        [self setMwl:NRMWLv1_1];
    }]];
    [alert addAction:[UIAlertAction cancelAlertAction:nil]];
    
    alert.popoverPresentationController.sourceView = self.mwlButton;
    alert.popoverPresentationController.sourceRect = self.mwlButton.frame;
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) setMwl:(NRMWL) newMwl {
    if (self.deck.mwl != newMwl) {
        self.deck.mwl = newMwl;
        [[NSNotificationCenter defaultCenter] postNotificationName:Notifications.DECK_CHANGED object:nil];
    }
}

@end
