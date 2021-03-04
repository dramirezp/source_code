//
//  VZoneController.m
//  voco
//
//  Created by David Ramirez on 8/23/12.
//  Copyright (c) 2012 com.navvo.ios. All rights reserved.
//

#include <netdb.h>
#include <arpa/inet.h>
#import "vocoAppDelegate.h"
#import "VZoneController.h"
#import "VocoConstants.h"
#import "CellSimple.h"
#import "Zone.h"
#import "Utils.h"
#import "ScanRange.h"
#import "vocoAppDelegate.h"
#import "VocoToast.h"
#import "Server.h"
#import "MusicSourcesController.h"
#import "HttpRequest.h"
#import "CustomPopoverBackgroundView.h"

@implementation VZoneController

@synthesize players;
@synthesize tablePlayers;
@synthesize viewControllerDelegate;
@synthesize uiViewMusicSource;
@synthesize uiLibrarySourceView;
@synthesize btnForgetZonesProperty;
@synthesize volumeViewController;
@synthesize btnViewMusicSourceProperty;
@synthesize controlsPlayingControllerDelegate;
@synthesize uiLibraryImage;
@synthesize needUpdatedContent;


UIImage *rowImage = nil;
UIImage *rowImagePlay = nil;
UIImage *rowImagePreferences = nil;
UIImage *rowImageSync = nil;

bool isShown = false;
UISlider *uisliderVolume;
int rowIndex = 0;


// we have to use this variable because we don't have the possibility to send the index
// between the alert and the method
int countTEMP = 0;

Zone *currentPlayer = nil;
NSString *zoneMac = nil;
NSIndexPath *selectedCellIndexPath;
NSIndexPath *selectedCellIndexPathOld = nil;
//NSArray *Serverlist;
//UIActionSheet *volumeSheet;
int comingRotation;
bool selectDevice = false;
bool updateNameDeviceLabel = true;
bool firstLoadInformation = false;
UIImage *sync_button_press;
UIImage *sync_button_unpress;
UIImage *currentBackground;
UIImage *unSelectedRowBackground;
UIImage *btnPlayImage;
UIImage *btnPauseImage;
UIImage *downArrow;
UIImage *upArrow;
UIImage *btnPauseImage;

//Controll the Music Source Controller
MusicSourcesController *mainMusicSourcesController;

- (id)init{
    self = [super init];
    if (self) {
        // Initialization code
        [self loadInformation:FALSE];
    }
    return self;
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self loadInformation:FALSE];
    }
    return self;
}

-(void)checkSizeForiPhone{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height > 480.0f) {
        self.frame = CGRectMake (0, 0, 320, 395);
        self.tablePlayers.frame= CGRectMake (0, 0, 320, 390);
    } else {
        self.frame = CGRectMake (0, 0, 320, 340);
        self.tablePlayers.frame= CGRectMake (0, 0, 320, 300);
    }
}

-(void)loadInformation:(BOOL) firstTime{
    
    needUpdatedContent = false;
    [self loadCommonObjects];
    [self reSizeScreen];
    firstLoadInformation = true;
    updateNameDeviceLabel = true;
    VocoDB *vocoDB = [[Utils getAppDelegate] getVocoDB];
    
    players = [[NSMutableArray alloc]init];
    players = (NSMutableArray *)[vocoDB getPlayers];
    zoneMac = [[Utils getAppDelegate] getSelectedZone];
    
    [self createStaticsRows];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_updatePlayers:) name:UPDATE_DB_VZONE object:nil ];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_refreshTable:) name:VOCO_NETWORK_LOST object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_refreshTable:) name:VOCO_NETWORK_CONNECTED object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_refreshTable:) name:VocoNowPlayingStatusChangeNotification object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(do_refreshScreen) name:ORIENTATION_CHANGE_DEVICE object:nil];
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(do_willRefreshScreen) name:ORIENTATION_CHANGE_DEVICE_WILL_ROTATION object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_refreshTable:) name:UPDATE_NOWPLAYING_INFORMATION_ZONE_SCREEN object:nil];
    //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_updateStatusSelectedZone) name:SELECTED_ZONE_STATUS_CHANGED object:nil ];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(do_lostCurrentZone) name:LOST_CURRENT_SELECTED_ZONE object:nil ];
    
    [self showMusicSource];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        [self hideShowLibrarySource];
    }
    
    comingRotation = 0;
    [btnForgetZonesProperty setTitle:NSLocalizedString(@"forgetZone", nil) forState:UIControlStateNormal];
    [btnViewMusicSourceProperty setTitle:NSLocalizedString(@"library_source_title", nil) forState:UIControlStateNormal];
    
    [tablePlayers reloadData];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (!firstTime) {
            [self checkSizeForiPhone];
        }
        
    }
}

-(void)loadCommonObjects{
    sync_button_press = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"sync_btn_press" ofType:@"png"]];
    sync_button_unpress = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"sync_btn" ofType:@"png"]];
    currentBackground = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"selected-zone-background" ofType:@"png"]];
    unSelectedRowBackground = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"unSelectedItem" ofType:@"png"]];
    btnPlayImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"play_btn" ofType:@"png"]];
    btnPauseImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"zone-pause_btn" ofType:@"png"]];
    downArrow = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"library-down-arrow" ofType:@"png"]];
    upArrow = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"library-up-arrow" ofType:@"png"]];
}

-(void)showMusicSource{
    [uiLibraryImage setImage:upArrow];
    NSString * name = @"MusicSources";
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        name =  [name stringByAppendingString:@"_iPad"];
    }
    
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:name owner:self options:nil];
    //Load the View
    mainMusicSourcesController = [subviewArray objectAtIndex:0];
    
    [mainMusicSourcesController loadInformation];
    mainMusicSourcesController.vZoneDelegate = self;
    mainMusicSourcesController.viewControllerDelegate = self.viewControllerDelegate;
    mainMusicSourcesController.controlsPlayingControllerDelegate = self.controlsPlayingControllerDelegate;
    [self.uiViewMusicSource addSubview:mainMusicSourcesController];
}

-(void)showMusicSourceSmallScreen:(int)index cellPlayer:(CellPlayer*)cellPlayer{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        Zone *currentPlayerMusicSource = [self resolvePlayer:index];
        
        UIImage *imageMusicSource = nil;
        
        CGRect newFrameSize;
        CGRect newButtonFrameSize;
        if (self.uiLibrarySourceView.frame.origin.x == 325) {
            currentPlayerMusicSource.openMusicSourceSmallDevice = true;
            [mainMusicSourcesController loadInformation:currentPlayerMusicSource];
            newFrameSize =  CGRectMake (50, 0, 320, 475);
            newButtonFrameSize =  CGRectMake (25, 15, 27,  80);
            
            imageMusicSource=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"source_tab_open" ofType:@"png"]];
        }else{
            currentPlayerMusicSource.openMusicSourceSmallDevice = false;
            newFrameSize =  CGRectMake (325 , 0, 320, 475);
            newButtonFrameSize =  CGRectMake (294, 15, 27,  80);
            imageMusicSource=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"source_tab_closed" ofType:@"png"]];
        }
        
        [cellPlayer.btnShowSourceProperty setImage:imageMusicSource forState:UIControlStateNormal];
        [UIView beginAnimations : @"Display notif" context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationBeginsFromCurrentState:FALSE];
        
        self.uiLibrarySourceView.frame = newFrameSize;
        cellPlayer.btnShowSourceProperty.frame = newButtonFrameSize;
        [UIView commitAnimations];
        
        imageMusicSource = nil;
        
    }
}

-(void)reSizeScreen{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIDeviceOrientationLandscapeRight || orientation == UIDeviceOrientationLandscapeLeft) {
        tablePlayers.frame =  CGRectMake(tablePlayers.frame.origin.x,tablePlayers.frame.origin.y , tablePlayers.frame.size.width, 570);
    }
}

// We are going to upload all the object
- (void)viewDidUnload {
    
    rowImage = nil;
    rowImagePlay = nil;
    rowImagePreferences = nil;
    rowImageSync = nil;
    
    //uisliderVolume = nil;
    currentPlayer = nil;
    zoneMac = nil;
    selectedCellIndexPath = nil;;
    selectedCellIndexPathOld = nil;
    //    Serverlist = nil;
    //volumeSheet = nil;
    
    if (mainMusicSourcesController != nil) {
        //[mainMusicSourcesController.updateMusicSource invalidate];
        //mainMusicSourcesController.updateMusicSource = nil;
        mainMusicSourcesController = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPDATE_DB_VZONE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VOCO_NETWORK_LOST object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VOCO_NETWORK_CONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VocoNowPlayingStatusChangeNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:ORIENTATION_CHANGE_DEVICE object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:SELECTED_ZONE_STATUS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPDATE_NOWPLAYING_INFORMATION_ZONE_SCREEN object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}
-(void)createStaticsRows{
    // Include the statics rows for this screen
    Zone *player = [[Zone alloc] init];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && players.count > 0) {
        player = [[Zone alloc] init];
        player.name = NSLocalizedString(@"forgetAllZones", nil);
        player.ipAddress =@"127.0.0.5";
        player.mac = LOCAL_DEVICE_ID;
        player.tag = FORGET_ZONES;
        [players addObject:player];
        
        player = [[Zone alloc] init];
        player.name = NSLocalizedString(@"preferences", nil);
        player.ipAddress =@"127.0.0.6";
        player.mac = LOCAL_DEVICE_ID;
        player.tag = PREFERENCES_ZONES;
        [players addObject:player];
        
    }
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"enableForceScanOption"] ) {
        player = [[Zone alloc] init];
        player.name = NSLocalizedString(@"scan_for_vzones", nil);
        player.zoneLabel = NSLocalizedString(@"force_scanner", nil);
        player.ipAddress =@"127.0.0.3";
        player.mac = LOCAL_DEVICE_ID;
        player.tag = FORCE_SCAN;
        [players addObject:player];
    }
    
    if (players.count == 0) {
        player = [[Zone alloc] init];
        player.name =  NSLocalizedString(@"Searching", nil);
        player.ipAddress =@"127.0.0.4";
        player.mac = LOCAL_DEVICE_ID;
        player.status = ZONE_OFFLINE;
        player.tag = SEARCHING;
        [players addObject:player];
    }
}

#pragma mark UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //    NSLog(@"PLAYER COUNT ================ %d", players.count);
    return players.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row>=[players count]) {
        NSLog(@"[cellForRowAtIndexPath] Requested row greater than players count, ignoring");
        return nil;
    }
    Zone *thisPlayer = [players objectAtIndex:indexPath.row];
    if (thisPlayer.tag != FORCE_SCAN && thisPlayer.tag != FORGET_ZONES && thisPlayer.tag != PREFERENCES_ZONES) {
        
        static NSString *CellIdentifier = @"DeviceCell";
        CellPlayer *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        
        if( nil == cell ) {
            NSArray *topLevelObjects;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CellPlayerView" owner:nil options:nil];
            }else{
                topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CellPlayerView_iPad" owner:nil options:nil];
            }
            cell= [topLevelObjects objectAtIndex:0];
            [cell loadConfiguration];
        }
        
        NSString *status;
        switch (thisPlayer.status) {
            case ZONE_OFFLINE:
                status = NSLocalizedString(@"ZONE_OFFLINE_TEXT", nil);
                [cell.uiIndicatorView stopAnimating];
                cell.uiIndicatorView.hidden= YES;
                cell.playPlayer.hidden = YES;
                // With this line of the code all the screen is going to clean :-)
                if(thisPlayer.nowPlayingData != nil){
                    thisPlayer.nowPlayingData = nil;
                }
                break;
            case ZONE_NEEDS_UPGRADE:
                status = NSLocalizedString(@"ZONE_NEEDS_UPGRADE_TEXT", nil);
                [cell.uiIndicatorView stopAnimating];
                cell.uiIndicatorView.hidden= YES;
                break;
            case ZONE_NEEDS_CONFIG:
                status = NSLocalizedString(@"ZONE_NEEDS_CONFIG_TEXT", nil);
                [cell.uiIndicatorView stopAnimating];
                cell.uiIndicatorView.hidden= YES;
                break;
            case ZONE_CONFIGURING:
                status = NSLocalizedString(@"ZONE_CONFIGURING_TEXT", nil);
                [cell.uiIndicatorView startAnimating];
                cell.uiIndicatorView.hidden = NO;
                break;
            case ZONE_STARTING:
                status = NSLocalizedString(@"ZONE_STARTING_TEXT", nil);
                [cell.uiIndicatorView startAnimating];
                cell.uiIndicatorView.hidden= NO;
                break;
            case ZONE_WAITING_SERVER:
                status = NSLocalizedString(@"ZONE_WAITING_SERVER_TEXT", nil);
                cell.uiIndicatorView.hidden= NO;
                [cell.uiIndicatorView startAnimating];
                break;
            case ZONE_READY:
                status = NSLocalizedString(@"ZONE_READY_TEXT", nil);
                cell.uiIndicatorView.hidden= YES;
                [cell.uiIndicatorView stopAnimating];
                break;
            default:
                status = NSLocalizedString(@"ZONE_OFFLINE_TEXT", nil);
                break;
        }
        
        if (thisPlayer.timestampLastOffline != nil) {
            // We are going to ignore some quick_stat
            if ([NSDate date] < thisPlayer.timestampLastOffline) {
                thisPlayer.status = ZONE_OFFLINE;
                status = NSLocalizedString(@"ZONE_OFFLINE_TEXT", nil);
                [cell.uiIndicatorView stopAnimating];
                cell.uiIndicatorView.hidden= YES;
                cell.playPlayer.hidden = YES;
                // With this line of the code all the screen is going to clean :-)
                if(thisPlayer.nowPlayingData != nil){
                    thisPlayer.nowPlayingData = nil;
                }
            }else{
                thisPlayer.timestampLastOffline = nil;
            }
        }
        
        [cell.imgDevice setImage:thisPlayer.deviceImage];
        cell.imgDevice.contentMode = UIViewContentModeScaleAspectFit ;
        
        cell.uiActivityIndicatorPlayer.hidden = YES;
        if(thisPlayer.tag == SEARCHING){
            [cell.uiActivityIndicatorPlayer setHidden:NO];
            [cell.uiActivityIndicatorPlayer startAnimating];
            [self updateDeviceName:thisPlayer.name notification:false status:thisPlayer.status];
            [mainMusicSourcesController refreshInformation];
            updateNameDeviceLabel = nil;
            [self hideButton: true];
        }
        
        status =[[@"(" stringByAppendingString:status]stringByAppendingString:@")"];
        //Hidden or show the controls
        [self showOptions:cell zone:thisPlayer];
        
        if (thisPlayer.status == ZONE_NEEDS_CONFIG) {
            cell.lblTitle.text = [thisPlayer.name stringByAppendingString:@" "];//stringByAppendingString:status];
            return cell;
        }
        
        [self assignTag:cell indexPathRow:indexPath];
        
        if (thisPlayer.status !=ZONE_READY) {
            cell.lblTitle.text = [thisPlayer.name stringByAppendingString:@" "];//stringByAppendingString:status];
            cell.lblMessage.text = status;
            //cell.imgDevice.image = nil;
            
        }else{
            NSString *songName =@"";
            NSString *artistName = @"";
            
            if ([thisPlayer nowPlayingData]!=nil){
                if ([[thisPlayer nowPlayingData]title]!=nil) {
                    songName = [[thisPlayer nowPlayingData] title];
                }
            }
            if ([thisPlayer nowPlayingData]!=nil){
                if([[thisPlayer nowPlayingData]artist]!=nil) {
                    artistName = [[thisPlayer nowPlayingData] artist];
                }
            }
            
            cell.lblTitle.text = thisPlayer.name ;
            
            NSString *messageTitle =  status;
            if ([songName isKindOfClass:[NSString class]]){
                if([artistName isKindOfClass:[NSString class]]) {
                    if (!([songName isEqualToString:@""] && [artistName isEqualToString:@""])) {
                        messageTitle= [status stringByAppendingString:[NSString stringWithFormat:@" %@: - %@ ",songName, artistName]];
                    }
                }
            }
            cell.lblMessage.text = messageTitle;
            
        }
        
        if (thisPlayer.status == ZONE_READY || thisPlayer.status == ZONE_WAITING_SERVER) {
            cell.btnShowSourceProperty.hidden = NO;
        }else{
            cell.btnShowSourceProperty.hidden = YES;
        }
        
        //Show or hidden the music source
        if (thisPlayer != nil && zoneMac != nil && thisPlayer.name != nil && ![thisPlayer.name isEqualToString:LOCAL_DEVICE_ID]) {
            if (![thisPlayer.nowPlayingData isKindOfClass:[NSNull class]]) {
                if (thisPlayer.nowPlayingData != nil) {
                    if (thisPlayer.nowPlayingData.syncMaster.length > 0) {
                        rowImageSync = sync_button_press;
                    }else{
                        rowImageSync = sync_button_unpress;
                    }
                }
            }
        }
        
        if ([zoneMac isEqualToString:thisPlayer.mac] ) {
            selectDevice = true;
            rowImage= currentBackground;
            cell.btnSettingProperty.hidden = NO;
            if (updateNameDeviceLabel) {
                [self updateDeviceName:thisPlayer.name notification:false status:thisPlayer.status];
                [mainMusicSourcesController refreshInformation];
                updateNameDeviceLabel = nil;
                
                bool hidden;
                hidden = (thisPlayer.status == ZONE_READY)?false:true;
                [self hideButton: hidden];
            }
        }else{
            rowImage=unSelectedRowBackground;
            cell.btnSettingProperty.hidden = YES;
            //cell.btnShowSourceProperty.hidden = YES;
        }
        
        //Show the image for Play or Pause in the table view
        NSDate *now = [NSDate date];
        // only process changes in play button if we have passed the interval
        int delta = ZONE_SCREEN_BUTTON_BLACKOUT_INTERVAL+1;
        if ([thisPlayer lastButtonAction]!=nil) {
            delta = [now timeIntervalSinceDate:[thisPlayer lastButtonAction]];
        }
        if ([thisPlayer lastButtonAction]==nil || delta>ZONE_SCREEN_BUTTON_BLACKOUT_INTERVAL) {
            BOOL isPlaying = false;
            // Vzone
            if (thisPlayer.nowPlayingData != nil) {
                if ([[thisPlayer nowPlayingData] mode] == ZONE_PLAYBACKMODE_PLAY) {
                    isPlaying = true;
                } else {
                    isPlaying = false;
                }
            }
            if (isPlaying) {
                rowImagePlay= btnPauseImage;
            } else {
                rowImagePlay=btnPlayImage ;
            }
            if (thisPlayer.status != ZONE_OFFLINE){
                [cell.playPlayer setImage:rowImagePlay forState:UIControlStateNormal];
                
            }
        } else {
            // ignoring updates
            NSLog(@"Ignoring update to play button for zone %@ - %@, delta %d", thisPlayer.name, thisPlayer.mac, delta);
        }
        cell.vZoneDelegate = self;
        [cell.selectPlayer setBackgroundImage:rowImage forState:UIControlStateNormal];
        [cell.syncronizeProperty setImage:rowImageSync forState:UIControlStateNormal];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor clearColor];
        
        rowImage =nil;
        rowImagePlay = nil;
        rowImagePreferences = nil;
        rowImageSync = nil;
        thisPlayer = nil;
        [cell setNeedsDisplay];
        
        return cell;
    }else{
        static NSString *CellIdentifier = @"CellSimple";
        CellSimple *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if( nil == cell ) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"CellSimple" owner:nil options:nil];
            cell= [topLevelObjects objectAtIndex:0];
        }
        
        cell.lblTitle.text = thisPlayer.name;
        cell.lblSubtitle.text = thisPlayer.zoneLabel;
        
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[ unSelectedRowBackground stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
        return cell;
    }
}

-(void)hideButton: (bool) hidden{
    if (viewControllerDelegate !=nil) {
        // [viewControllerDelegate showHideButton:hidden showSongs:false ];
    }
}


-(void)assignTag:(CellPlayer *)cell indexPathRow:(NSIndexPath *)indexPath{
    cell.selectPlayer.tag = indexPath.row;
    cell.playPlayer.tag  = indexPath.row;
    //cell.preferencePlayer.tag  = indexPath.row;
    cell.volumePlayer.tag  = indexPath.row;
    cell.syncronizeProperty.tag = indexPath.row;
    cell.upgradeProperty.tag = indexPath.row;
    cell.btnSettingProperty.tag  = indexPath.row;
    cell.btnShowSourceProperty.tag= indexPath.row;
}

//Show some options and Preferences is the status is OFFLine
-(void)showOptions:(CellPlayer*)cell zone:(Zone *)zoneForRow{
    int zoneStatus = zoneForRow.status;
    bool upgradeRequireStatus = NO;
    
    switch (zoneStatus) {
        case ZONE_NEEDS_CONFIG:
            cell.playPlayer.hidden = YES;
            cell.volumePlayer.hidden = YES;
            cell.syncronizeProperty.hidden = YES;
            cell.btnSettingProperty.hidden = YES;
            break;
        case ZONE_OFFLINE:
        case ZONE_CONFIGURING:
            cell.playPlayer.hidden = YES;
            cell.volumePlayer.hidden = YES;
            cell.syncronizeProperty.hidden = YES;
            cell.upgradeProperty.hidden = YES;
            cell.btnSettingProperty.hidden = YES;
            break;
        case ZONE_WAITING_SERVER:
            //case ZONE_NEEDS_UPGRADE:
        case ZONE_STARTING:
            //Check if we have to show or not the upgrade button
            if (zoneForRow.upgradeAvailable == 0 && zoneForRow.status != ZONE_NEEDS_UPGRADE) {
                cell.upgradeProperty.hidden = YES;
            }else{
                if(zoneForRow.status != ZONE_OFFLINE){
                    cell.upgradeProperty.hidden = NO;
                    if (zoneForRow.version < MIN_FW_VERSION_FOR_VZONE) {
                        upgradeRequireStatus = YES;
                        break;
                    }
                }else{
                    cell.upgradeProperty.hidden = YES;
                }
            }
            cell.playPlayer.hidden = YES;
            cell.volumePlayer.hidden = YES;
            cell.syncronizeProperty.hidden = YES;
            cell.btnSettingProperty.hidden = NO;
            break;
            
        default:
            //Check if we have to show or not the upgrade button
            if (zoneForRow.upgradeAvailable == 0 && zoneForRow.status != ZONE_NEEDS_UPGRADE) {
                cell.upgradeProperty.hidden = YES;
            }else{
                if(zoneForRow.status != ZONE_OFFLINE){
                    cell.upgradeProperty.hidden = NO;
                    if (zoneForRow.version < MIN_FW_VERSION_FOR_VZONE) {
                        upgradeRequireStatus = YES;
                        break;
                    }
                }else{
                    cell.upgradeProperty.hidden = YES;
                }
            }
            cell.playPlayer.hidden = NO;
            cell.volumePlayer.hidden = NO;
            cell.syncronizeProperty.hidden = NO;
            cell.uiViewMusicSource.hidden = NO;
            cell.btnSettingProperty.hidden = NO;
            break;
    }
    
    // If the Device is in Configure status, it has to hidden all the controls
    // only the configure button will show for this status
    if (upgradeRequireStatus) {
        cell.playPlayer.hidden = YES;
        cell.volumePlayer.hidden = YES;
        cell.syncronizeProperty.hidden = YES;
        cell.uiViewMusicSource.hidden = YES;
        cell.btnSettingProperty.hidden = NO;
        NSLog(@"upgradeRequireStatus");
    }
    
}

#pragma mark UITableViewDelegate Methods
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Zone *thisPlayer = [players objectAtIndex:indexPath.row];
    
    if ([thisPlayer.name isEqualToString:@"Scan"]){
        [self scanForZones];
    }
    
    if(thisPlayer.tag == FORGET_ZONES){
        [self forgetAllPlayers];
    }
    
    if (thisPlayer.tag == PREFERENCES_ZONES) {
        if (viewControllerDelegate !=nil) {
            [viewControllerDelegate showPreferences];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

-(void)scanForZones {
    NSLog(@"[scanForZones]");
    @synchronized(alertScanning) {
        scanProgress=0;
    }
    NSString *ip = [Utils getDeviceIPAddress];
    if (ip) {
        alertScanning = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"message_scanning_title", nil) message:NSLocalizedString(@"message_scanning_alert", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"dismiss", nil) otherButtonTitles:nil];
        alertScanningProgress = [[UIProgressView alloc] init];
        [alertScanningProgress setProgress:0];
        alertScanningProgress.frame = CGRectMake(15, 100, 255, 30);
        [alertScanning addSubview:alertScanningProgress];
        if (![alertScanning isVisible]) {
            [alertScanning setTitle:NSLocalizedString(@"message_scanning_title", nil)];
            [alertScanning show];
        }
        NSLog(@"[scanForZones] Found IP: %@", ip);
        NSRange range = [ip rangeOfString:@"." options:NSBackwardsSearch];
        NSLog(@"range.location: %lu", (unsigned long)range.location);
        NSString *substring = [ip substringFromIndex:range.location+1];
        NSString *base = [ip substringToIndex:range.location+1];
        NSLog(@"substring: '%@' base: '%@'", substring, base);
        for (int i=0; i<26; i++) {
            ScanRange *range = [[ScanRange alloc] init];
            range.ipBase = [[NSString alloc] initWithString:base];
            range.start = 1+10*i;
            range.count = 10;
            // last group only has 4 ips 251, 252, 253, 254
            if (range.start == 251) range.count = 4;
            // spawn the threads
            [NSThread detachNewThreadSelector:@selector(rangeScanner:) toTarget:self withObject:range];
        }
    } else {
        NSString *message =NSLocalizedString(@"device_cancel_scan", nil);
        UIAlertView *errorMessage = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"act_error_title", nil)  message:message delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"done", nil), nil];
        [errorMessage show];
        errorMessage = nil;
    }
}


-(void) rangeScanner: (ScanRange *)range {
    NSLog(@"[rangeScanner] ipBase %@ start %d count %d", range.ipBase, range.start, range.count);
    @try {
        NSDictionary *quick_stat;
        NSString *base = [[NSString alloc] initWithString:range.ipBase];
        int start = range.start;
        int count = range.count;
        for (int i=start; i<(start+count); i++) {
            NSString *ip = [[NSString alloc] initWithFormat:@"%@%d", base, i];
            NSLog(@"[rangeScanner] Scanning IP: %@", ip);
            @try {
                BOOL passTest = false;
                NSString *url = [[NSString alloc] initWithFormat:@"http://%@/vzc/quick_stat", [currentPlayer ipAddress]];
                HttpRequest *myRequest = [[HttpRequest alloc] init];
                NSString *response = [myRequest fetchUrl:url];
                NSString *trimmedResponse = [response stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (trimmedResponse != nil && [trimmedResponse length] > 0) {
                    // we need to JSON parse the response to make sure it is a valid quick_stat and not an http error page
                    // SBJsonParser* result=[[SBJsonParser alloc]init];
                    // quick_stat = [result objectWithString:trimmedResponse];
                    
                    NSError* error;
                    NSData* data = [trimmedResponse dataUsingEncoding:NSUTF8StringEncoding];
                    quick_stat = [NSJSONSerialization
                                  JSONObjectWithData:data //1
                                  options:kNilOptions
                                  error:&error];
                    
                    // test that system.uuid app.smapp.device.id and network.health.status are there
                    if (quick_stat != nil && [Utils dictionaryHasKey: quick_stat key: @"system.uuid"] &&
                        [Utils dictionaryHasKey: quick_stat key: @"app.smapp.device.id"] &&
                        [Utils dictionaryHasKey: quick_stat key: @"network.health.status"]) {
                        passTest = true;
                    }
                }
                if (passTest) {
                    NSLog(@"[rangeScanner] Found Valid Zone at ip %@", ip);
                    [[[Utils getAppDelegate] getVocoDB] processVzoneUdpResponse: quick_stat fromHost:ip];
                }
            } @catch (NSException *exception) {
                NSLog(@"[rangeScanner] ERROR Scanning IP %@", ip);
            }
            // processed 1 ip update count
            @synchronized(alertScanning) {
                scanProgress+=1;
                NSLog(@"[rangeScanner] scanProgress %d", scanProgress);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (alertScanning!=nil && [alertScanning isVisible]) {
                        float progress = (float)scanProgress/(float)254;
                        NSLog(@"[rangeScanner] progress %f", progress);
                        [alertScanningProgress setProgress:progress];
                        if (scanProgress>=254) {
                            // we are done, hide the alert
                            [alertScanning dismissWithClickedButtonIndex:0 animated:YES];
                        }
                    }
                });
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"[rangeScanner] ERROR %@", [exception reason]);
    }
}


-(void)forgetAllPlayers{
    needUpdatedContent = true;
    [[[Utils getAppDelegate] getVocoDB] deleteAllDbZone];
    [[[Utils getAppDelegate] getVocoDB] clearCacheDB];
    [[[Utils getAppDelegate] getVocoDB] clearServerScanTokenDB];
    [[[Utils getAppDelegate] getVocoDB] clearCacheStats];
    [[[Utils getAppDelegate] getVocoDB] clearPendingPreCacheServer];
    @synchronized (players){
        [players removeAllObjects];
        [self createStaticsRows];
    }
    zoneMac = nil;
    [[Utils getAppDelegate] switchZone:nil];
    [self refreshController];
    [VocoToast showWithText:NSLocalizedString(@"remove_all_zones", nil)];
}


// Function from the controls in the cell
- (void)updateDeviceSelected: (int)index{
    //dispatch_async(dispatch_get_main_queue(), ^{
    currentPlayer = nil;
    currentPlayer = [self resolvePlayer:index];
    
    [players removeObject:currentPlayer];
    [players insertObject:currentPlayer atIndex:0];
    
    [[[Utils getAppDelegate]getVocoDB] moveZoneToTop:currentPlayer.mac];
    [[Utils getAppDelegate] switchZone:currentPlayer.mac];
    zoneMac = currentPlayer.mac;
    
    //Close the tabs in the phone
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (self.uiLibrarySourceView.frame.origin.x != 325) {
            [self closeMusicSourceSmallDevice];
        }
    }
    
    [UIView transitionWithView:self duration:1. options:(UIViewAnimationOptionTransitionFlipFromLeft) animations:^{
        [mainMusicSourcesController loadInformation];
        [self refreshController];
        Zone *tempZone = [[Utils getAppDelegate]getCurrentPlayer];
        if ([tempZone status]==ZONE_NEEDS_UPGRADE && tempZone.version < MIN_FW_VERSION_FOR_VZONE) {
            [self upgradeZone:0];
        }
        tempZone = nil;
        
    } completion:^(BOOL finished) {
    }];
}

-(void)closeMusicSourceSmallDevice{
    CGRect newFrameSize;
    CGRect newButtonFrameSize;
    newFrameSize =  CGRectMake (325 , 0, 320, 475);
    newButtonFrameSize =  CGRectMake (294, 15, 27,  80);
    
    UIImage *imageMusicSource=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"source_tab_closed" ofType:@"png"]];
    self.uiLibrarySourceView.frame = newFrameSize;
    
    NSArray *cells = [tablePlayers visibleCells];
    for (CellPlayer *cell in cells)
    {
        //Change the image for the tab button
        if (cell.btnShowSourceProperty.frame.origin.x !=294) {
            cell.btnShowSourceProperty.frame = newButtonFrameSize;
            [cell.btnShowSourceProperty setImage:imageMusicSource forState:UIControlStateNormal];
            break;
        }
    }
}

- (void)updatePlayMusic: (int)index{
    NSIndexPath *nowIndex = [NSIndexPath indexPathForRow:index inSection:0];
    CellPlayer *cell = (CellPlayer *)[self.tablePlayers cellForRowAtIndexPath:nowIndex];
    Zone *selectedPlayer = [self resolvePlayer:index];
    BOOL isPlaying = false;
    
    // Vzone
    [selectedPlayer setLastButtonAction:[NSDate date]];
    if ([selectedPlayer nowPlayingData]!=nil && [[selectedPlayer nowPlayingData] mode]==ZONE_PLAYBACKMODE_PLAY) {
        if ([[selectedPlayer nowPlayingData] source]==ZONE_SOURCE_VMSSERVER) {
            [selectedPlayer sendPlayerPause];
        } else if ([[selectedPlayer nowPlayingData] source]==ZONE_SOURCE_VIDEO) {
            [selectedPlayer sendZmcPause];
        }
        isPlaying = false;
        [[selectedPlayer nowPlayingData] setMode:ZONE_PLAYBACKMODE_PAUSE];
    } else {
        if ([[selectedPlayer nowPlayingData] source]==ZONE_SOURCE_VMSSERVER) {
            [selectedPlayer sendPlayerPlay];
        } else if ([[selectedPlayer nowPlayingData] source]==ZONE_SOURCE_VIDEO) {
            [selectedPlayer sendZmcResume];
        }
        isPlaying = true;
        [[selectedPlayer nowPlayingData] setMode:ZONE_PLAYBACKMODE_PLAY];
    }
    
    
    if ([selectedPlayer.mac isEqualToString:[[Utils getAppDelegate] getSelectedZone]]) {
        [controlsPlayingControllerDelegate updatePlayOrPause:isPlaying];
    }
    
    if (isPlaying) {
        rowImage=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"zone-pause_btn" ofType:@"png"]];
    } else {
        rowImage=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"play_btn" ofType:@"png"]];
    }
    [cell.playPlayer setImage:rowImage forState:UIControlStateNormal];
    [cell setNeedsDisplay];
}

- (void)updateVolumenDevice:(int)index sender:(id)sender{
    Zone *selectedPlayer = [self resolvePlayer:index];
    NSLog(@"Volume %d", selectedPlayer.nowPlayingData.volume);
    volumeViewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        rowIndex = index;
        /*[[Utils getAppDelegate] showPleaseWait: @"Getting Volume" view:self];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:[NSNumber numberWithInt:index] forKey:@"index"];
        [NSThread detachNewThreadSelector:@selector(getVolumen:) toTarget:self withObject:dict];*/
        [viewControllerDelegate showVolumeDialog: selectedPlayer];
    }else{
        if (_volumeViewPopover != nil) {
            [_volumeViewPopover dismissPopoverAnimated:YES];
            _volumeViewPopover = nil;
        }
        
        if (volumeViewController == nil) {
            volumeViewController = [[VolumeViewController alloc]init];
            volumeViewController.delegate = self;
            volumeViewController.ControlsPlayingDelegate = (id)controlsPlayingControllerDelegate;
            volumeViewController.selectedZone = selectedPlayer;
        }
        
        if (_volumeViewPopover == nil) {
            _volumeViewPopover = [[UIPopoverController alloc] initWithContentViewController:volumeViewController];
            _volumeViewPopover.popoverBackgroundViewClass = [CustomPopoverBackgroundView class];
            [_volumeViewPopover presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            //The color picker popover is showing. Hide it.
            [_volumeViewPopover dismissPopoverAnimated:YES];
            volumeViewController = nil;
        }
    }
    
}
/*
-(void)drawVolumeSheet:(int)volume{
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIView *view = [[UIView alloc]init];
        view.frame = CGRectMake(0, 10, 400, 100);
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:(id)self
                                                        cancelButtonTitle:@"OK"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        [actionSheet showInView:self];
        
        
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(115,1, 100, 25)];
        label.numberOfLines = 1;
        label.text = @"Set Volume";
        
        CGRect frameSlider = CGRectMake(10, 50, 300.0, 50.0);
        uisliderVolume = [[UISlider alloc] initWithFrame:frameSlider];
        [uisliderVolume addTarget:self action:@selector(updatedVolume) forControlEvents:UIControlEventTouchUpInside];
        [uisliderVolume setBackgroundColor:[UIColor clearColor]];
        uisliderVolume.minimumValue = 0;
        uisliderVolume.maximumValue = 100;
        uisliderVolume.continuous = YES;
        uisliderVolume.value = volume;
        
        UIImage *maxImage = [UIImage imageNamed:@"volume-channel.png"];
        UIImage *minImage = [UIImage imageNamed:@"volume-channel-fill.png"];
        minImage = [minImage resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 306, 25)];
        maxImage = [maxImage resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 306, 25)];
        [uisliderVolume setMaximumTrackImage:maxImage forState:UIControlStateNormal];
        [uisliderVolume setMinimumTrackImage:minImage forState:UIControlStateNormal];
        [uisliderVolume setThumbImage:[UIImage imageNamed:@"volume_thumb_large.png"] forState:UIControlStateNormal];
        
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        
        int adjust = 100;
        if ([[Utils getAppDelegate]isOS7]) {
            adjust = 130;
        }
        CGRect rect;
        //expand the action sheet
        rect = actionSheet.frame;
        rect.size.height +=adjust;
        rect.origin.y -= adjust;
        actionSheet.frame = rect;
        
        //Displace all buttons
        for (UIView *vButton in actionSheet.subviews) {
            rect = vButton.frame;
            rect.origin.y += adjust;
            if ([[Utils getAppDelegate]isOS7]) {
                rect.origin.x = 20;
                rect.size.height = 50;
                rect.size.width = 280;
            }
            vButton.frame = rect;
            if ([vButton isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)vButton; //[UIButton buttonWithType:UIButtonTypeCustom];
                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"alert-gray-button.png"]];
                image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
                [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
                [button setBackgroundImage:image forState:UIControlStateNormal];
                
            }
            
        }
        [view.self addSubview:label];
        [view.self addSubview:uisliderVolume];
        [actionSheet setBackgroundColor:[UIColor colorWithRed:56/255.0 green:55/255.0 blue:48/255.0 alpha:1]];
        
        //Add the new view
        [actionSheet addSubview:view];
        
        CGRect frameSheet = CGRectMake(0.0, 350, 320, 50);
        volumeSheet.frame = frameSheet;
    }
}

-(void)updatedVolume{
    [NSThread detachNewThreadSelector:@selector(do_updatedVolume) toTarget:self withObject:nil];
}

//Updated the volume in the device
-(void)do_updatedVolume{
    Zone *selectedPlayer = [self resolvePlayer:(int)rowIndex];
    [selectedPlayer setTimeStampVolume:[NSDate date]];
    [selectedPlayer setZoneVolume:uisliderVolume.value];
    selectedPlayer.nowPlayingData.oldVolume = uisliderVolume.value;
    [volumeSheet dismissWithClickedButtonIndex:0 animated:YES];
    volumeSheet = nil;
    [NSThread exit];
}

-(void)dismissActionSheet {
    [volumeSheet dismissWithClickedButtonIndex:0 animated:YES];
}

//Get the current volume in the device from the now playing broadcast
-(void)getVolumen: (NSMutableDictionary *)dict{
    int result = 0;
    int index = [[dict objectForKey:@"index"]intValue];
    Zone *selectedPlayer = [self resolvePlayer:(int)index];
    result = [[selectedPlayer nowPlayingData]volume];
    
    [[Utils getAppDelegate] hidePleaseWait];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self drawVolumeSheet:result];
    });
    [NSThread exit];
}*/

- (Zone *)resolvePlayer:(int)index{
    Zone *selectedPlayer = [players objectAtIndex:index];
    return selectedPlayer;
}

-(void)updateDeviceName:(NSString *)playerName notification:(bool)notification status:(int)status{
    [viewControllerDelegate updateDeviceName:playerName notification:notification status:status];
}

-(void)settings:(int)index{
    if (viewControllerDelegate !=nil) {
        [viewControllerDelegate showSettings];
    }
}


-(void)upgradeZone:(int)index{
    Zone *zone = [self resolvePlayer:index];
    NSLog(@"[VZoneController | upgradeZone] Zone Name %@",zone.name);
    NSString *available = [NSString stringWithFormat:@"%d", zone.availableVersion];
    NSString *version = [NSString stringWithFormat:@"%d",zone.version ];
    NSString *min_fw_version_for_vzone = [NSString stringWithFormat:@"%d",MIN_FW_VERSION_FOR_VZONE ];
    NSString *strMessage;
    
    if (zone.version<MIN_FW_VERSION_FOR_VZONE && !zone.upgradeFailed) {
        strMessage = [NSString stringWithFormat:NSLocalizedString(@"requestUpgradeUnder", nil) ,version,min_fw_version_for_vzone];
    } else if (zone.version<MIN_FW_VERSION_FOR_VZONE && zone.upgradeFailed) {
        strMessage =[NSString stringWithFormat:NSLocalizedString(@"requestUpgradePreviousFailed", nil) ,version,min_fw_version_for_vzone];
    } else if (zone.upgradeFailed) {
        strMessage =[NSString stringWithFormat:NSLocalizedString(@"requestUpgradeNewPreviousFailed", nil) ,version,available];
    } else if (zone.upgradeAvailable) {
        strMessage =[NSString stringWithFormat:NSLocalizedString(@"requestUpgradeNewAvailable", nil) ,version,available];
    } else {
        strMessage =[NSString stringWithFormat:NSLocalizedString(@"requestUpgradeAvailable", nil) ,version,available];
    }
    
    BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"applyUpgrade", nil) message:strMessage];
    [alert setCancelButtonWithTitle:NSLocalizedString(@"cancel", nil) block:nil];
    [alert addButtonWithTitle:NSLocalizedString(@"ok", nil) block:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            zone.status = ZONE_OFFLINE;
        });
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            if (zone.version >= MIN_FIRMWARE_COMMAND_VERSION) {
                [[[Utils getAppDelegate] getVocoDB] TagVzoneOfflineByMac:[zone mac]]; // this sets the zone status as offline
                [zone setFirmwareUpgrade];
            }else{
                [zone setFirmwareUpgradeOk];
                [zone setFirmwareUpgradeFailed];
                [zone setFirmwareUpgradeStart];
                [[[Utils getAppDelegate] getVocoDB] TagVzoneOfflineByMac:[zone mac]]; // this sets the zone status as offline
                [zone reboot];
            }
        });
    }];
    [alert show];
    alert = nil;
}

//Changes the size into the cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 105;
}

// call refreshTable on the main thread
-(void)do_refreshTable:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshTable];
    });
}

// This method refresh all the table
-(void)refreshTable{
    
    [tablePlayers reloadData];
}

// call updatePlayers on the main thread
-(void)do_updatePlayers:(NSNotification *) notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayers];
    });
}

-(void)updatePlayers{
    // refresh current Zones in DB
    zoneMac = [[Utils getAppDelegate] getSelectedZone];
    
    if (zoneMac !=nil && (![zoneMac isEqualToString:LOCAL_DEVICE_ID])) {
        [[[Utils getAppDelegate]getVocoDB] moveZoneToTop:zoneMac];
    }
    
    if (players != nil) {
        players = nil;
    }
    players = [[NSMutableArray alloc]init];
    players = (NSMutableArray *)[[[Utils getAppDelegate] getVocoDB] getPlayers];
    
    if (players.count > 0) {
        //Now verify our selected zone is still in the list
        bool foundZone = false;
        for (Zone *currentZone in players) {
            if ([currentZone.mac caseInsensitiveCompare: zoneMac] == NSOrderedSame) {
                if (firstLoadInformation == false) {
                    foundZone = true;
                }else{
                    if (currentZone.status != ZONE_OFFLINE) {
                        foundZone = true;
                    }
                }
                firstLoadInformation = false;
                break;
            }
        }
        if (!foundZone) {
            Zone *firstZone = [[[Utils getAppDelegate]getVocoDB]getPlayerByMac:zoneMac]; //[[[Utils getAppDelegate]getVocoDB]getFirstZone];
            
            if (firstZone == nil) {
                firstZone = [[[Utils getAppDelegate]getVocoDB]getFirstZone];
            }
            
            [players removeObject:firstZone];
            
            if (players!=nil) {
                if (players.count > 0) {
                    [players insertObject:firstZone atIndex:0];
                }else{
                    [players addObject:firstZone];
                }
            }else{
                players = [[NSMutableArray alloc]init];
                [players addObject:firstZone];
            }
           

            currentPlayer = firstZone;
            [[Utils getAppDelegate] switchZone:firstZone.mac];
            zoneMac = firstZone.mac;
        }
        
        if(needUpdatedContent){
            needUpdatedContent = false;
            [self refreshController];
        }
    }
    
    // Add back the static rows
    [self createStaticsRows];
    [tablePlayers reloadData];
    
}

// This method refresh the Specific Cell
-(void)refreshCell: (NSIndexPath*)index{
    [self.tablePlayers beginUpdates];
    [self.tablePlayers reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone];
    [self.tablePlayers endUpdates];
}

-(void)forgetPlayer:(Zone *)player{
    @synchronized (players){
        for (Zone *tempZone in players) {
            if([tempZone.mac isEqualToString:player.mac]){
                [players removeObject:tempZone];
                [[[Utils getAppDelegate]getVocoDB]purgeZone:player.mac];
                [self updateDeviceSelected:0];
                break;
            }
        }
        
        Zone *firstZone = [[[Utils getAppDelegate]getVocoDB]getFirstZone];
        currentPlayer = firstZone;
        [[Utils getAppDelegate] switchZone:firstZone.mac];
        zoneMac = firstZone.mac;
        [self refreshController];
    }
}

-(void)refreshController{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tablePlayers reloadData];
        
        
        // [self performSelector:(@selector(refreshTable)) withObject:nil afterDelay:0.2];
        //move the row to the top
        [tablePlayers scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        selectDevice = true;
        if (viewControllerDelegate !=nil) {
            [self updateDeviceName:currentPlayer.name notification:true status:currentPlayer.status];
            [mainMusicSourcesController refreshInformation];
            if (currentPlayer.status == ZONE_READY) {
                [self hideButton:false];
            }else{
                [self hideButton:true];
            }
        }
        
        
    });
}

-(void)syncSection:(int)index{
    Zone *playerDetail = [self resolvePlayer:index];
    
    if (viewControllerDelegate !=nil) {
        [viewControllerDelegate showSyncScreen:playerDetail];
    }
}


-(void)updateSelectedServer{
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideShowLibrarySource];
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.uiLibrarySourceView.frame.origin.x != 325) {
                [UIView animateWithDuration:0.25 animations:^{
                    [self closeMusicSourceSmallDevice];
                }];
            }
        });
    }
}

-(void)touchPreset:(int)index presetNumber:(int)presetNumber{
    Zone *selectedPlayer = [self resolvePlayer:index];
    [selectedPlayer playPreset:presetNumber];
}


- (IBAction)btnForgetZones:(id)sender {
    [self forgetAllPlayers];
}

- (IBAction)btnShowHiddeLibrary:(id)sender {
    [self hideShowLibrarySource];
}

-(void)hideShowLibrarySource{
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        if (isShown) {
            [UIView animateWithDuration:0.25 animations:^{
                [uiLibraryImage setImage:upArrow];
                tablePlayers.frame = tablePlayers.frame =  CGRectMake(tablePlayers.frame.origin.x,tablePlayers.frame.origin.y , tablePlayers.frame.size.width, 570);
                uiLibrarySourceView.frame = uiLibrarySourceView.frame =  CGRectMake(uiLibrarySourceView.frame.origin.x,601 , uiLibrarySourceView.frame.size.width, uiLibrarySourceView.frame.size.height);
            }];
            isShown = false;
        } else {
            [mainMusicSourcesController loadInformation];
            [UIView animateWithDuration:0.25 animations:^{
                [uiLibraryImage setImage:downArrow];
                tablePlayers.frame = tablePlayers.frame =  CGRectMake(tablePlayers.frame.origin.x,tablePlayers.frame.origin.y , tablePlayers.frame.size.width, 381);
                uiLibrarySourceView.frame =  uiLibrarySourceView.frame =  CGRectMake(uiLibrarySourceView.frame.origin.x,381 , uiLibrarySourceView.frame.size.width, uiLibrarySourceView.frame.size.height);
            }];
            isShown = true;
        }
    }else{
        NSIndexPath *nowIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        CellPlayer *cellPlayer = (CellPlayer *)[self.tablePlayers cellForRowAtIndexPath:nowIndex];
        [self showMusicSourceSmallScreen:0 cellPlayer:cellPlayer];
        
    }
}

-(void)changeDeviceStatus:(int)status{
    currentPlayer.status = status;
    [tablePlayers reloadData];
    [viewControllerDelegate updateDeviceName:currentPlayer.name notification:true status:status];
    
}


-(void)do_lostCurrentZone{
    currentPlayer.status = ZONE_OFFLINE;
}

-(void)updatePlayOrPause:(bool)isPlaying{
    UIImage *rowImage;
    if (isPlaying) {
        rowImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"zone-pause_btn" ofType:@"png"]];
    }else{
        rowImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"play_btn" ofType:@"png"]];
    }
    
    NSIndexPath *nowIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    CellPlayer *cell = (CellPlayer *)[self.tablePlayers cellForRowAtIndexPath:nowIndex];
    [cell.playPlayer setImage:rowImage forState:UIControlStateNormal];
    [cell setNeedsDisplay];
}

-(void)refreshControllerAfterServerChanged{
    [tablePlayers reloadData];
}

@end

