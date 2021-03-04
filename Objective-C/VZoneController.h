//
//  VZoneController.h
//  voco
//
//  Created by David Ramirez on 8/23/12.
//  Copyright (c) 2012 com.navvo.ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellPlayer.h"
#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"
#import "VolumeViewController.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"
#import "SDWebImageManager.h"


@class VZoneController;

@protocol ViewControllerDelegate <NSObject>
-(void)updateDeviceName: (NSString *)playerName notification:(bool)notification status:(int)status;
-(Zone *)getPlayerSelected;
-(void)showSyncScreen:(Zone *)player;
-(void)showPreferences;
//-(void)showHideButton: (bool)hidden showSongs:(bool)showSongs;
-(void)showSettings;
-(void)showVolumeDialog:(Zone *)player;
@end

@protocol ControlsPlayingControllerDelegate <NSObject>
-(void)updatePlayOrPause: (bool)isPlaying;
@end



@interface VZoneController : UIView <UITableViewDataSource, UITableViewDelegate, VZoneDelegate,UIGestureRecognizerDelegate,VolumeViewControllerDelegate>
{
    NSMutableArray *players;
    
@private
    UIAlertView *alertScanning;
    UIProgressView *alertScanningProgress;
    int scanProgress;
    
}

@property (nonatomic, strong) VolumeViewController *volumeViewController;
@property (nonatomic, strong) UIPopoverController *volumeViewPopover;
@property (strong, nonatomic) IBOutlet UIButton *btnViewMusicSourceProperty;

//Screen Propertys
@property (weak, nonatomic) IBOutlet UITableView *tablePlayers;
@property (strong,nonatomic) NSMutableArray *players;;
@property (strong, nonatomic) IBOutlet UIView *uiViewMusicSource;
@property (strong, nonatomic) IBOutlet UIView *uiLibrarySourceView;
@property (strong, nonatomic) IBOutlet UIButton *btnForgetZonesProperty;

@property (strong, nonatomic) IBOutlet UIImageView *uiLibraryImage;

@property (nonatomic, assign) BOOL needUpdatedContent;


- (IBAction)btnForgetZones:(id)sender;
//- (IBAction)btnPreferences:(id)sender;
- (IBAction)btnShowHiddeLibrary:(id)sender;

//Protocol Property
@property (strong,nonatomic) id <ViewControllerDelegate> viewControllerDelegate;
@property (strong,nonatomic) id <ControlsPlayingControllerDelegate> controlsPlayingControllerDelegate;

//Methods
-(void)loadInformation:(BOOL) firstTime;
-(void)viewDidUnload;
-(void)do_updatePlayers:(NSNotification *) notification;
-(void)refreshControllerAfterServerChanged;
@end
