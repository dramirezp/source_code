//
//  AutoUpgradeController.m
//  voco
//
//  Created by David Ramirez on 10/4/12.
//  Copyright (c) 2012 com.navvo.ios. All rights reserved.
//

#import "AutoUpgradeController.h"
#import "Utils.h"


@implementation AutoUpgradeController

@synthesize btnUpgradeYesProperty;
@synthesize btnUpgradeNoProperty;
@synthesize uiViewBackground;
@synthesize viewControllerDelegate;
@synthesize uiViewMain;
@synthesize btnSaveProperty;
@synthesize btnCancelProperty;
@synthesize lblTitle;
@synthesize lblMessage;
@synthesize lblAutomaticYes;
@synthesize lblAutomaticNo;


UIImage *rowImageUnSelected;
UIImage *rowImageSelect;
bool valueChosen = true;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)loadScreen:(Zone *)selectedPlayer{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.uiViewBackground.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        lblTitle.text = NSLocalizedString(@"auto_upgrade", nil);
        lblMessage.text = NSLocalizedString(@"vzw_screen_upgrades", nil);
        lblAutomaticYes.text = NSLocalizedString(@"vzw_option_upgrades_auto", nil);
        lblAutomaticNo.text = NSLocalizedString(@"vzw_option_upgrades_manual", nil);
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
            //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reSizeScreen) name:ORIENTATION_CHANGE_DEVICE object:nil];
            [self reSizeScreen];
        }
        
        UIImage *background = [UIImage imageNamed:@"alert-window.png"];//[UIImage imageNamed:@"action-sheet-panel.png"];
        background = [background stretchableImageWithLeftCapWidth:0 topCapHeight:30];
        UIImageView *modalBackground = [[UIImageView alloc] initWithFrame:uiViewMain.bounds];
        modalBackground.image = background;
        modalBackground.contentMode = UIViewContentModeScaleToFill;
        [uiViewMain insertSubview:modalBackground atIndex:0];
        
        
        UIImage *image = [UIImage imageNamed:@"alert-gray-button.png"];
        image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
        [btnSaveProperty setBackgroundImage:image forState:UIControlStateNormal];
        [btnSaveProperty setTitle:NSLocalizedString(@"save", nil) forState:UIControlStateNormal];
        [btnSaveProperty setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnSaveProperty setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        image = [UIImage imageNamed:@"alert-black-button.png"];
        image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
        [btnCancelProperty setBackgroundImage:image forState:UIControlStateNormal];
        [btnCancelProperty setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
        [btnCancelProperty setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnCancelProperty setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        btnSaveProperty.titleLabel.font = [UIFont systemFontOfSize:18];
        btnCancelProperty.titleLabel.font = [UIFont systemFontOfSize:18];
        
        [self sendSubviewToBack:uiViewBackground];
        rowImageUnSelected=[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"radio_btn" ofType:@"png"]];
        rowImageSelect =[UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"radio_btn_press" ofType:@"png"]];
        player = selectedPlayer;
        //dispatch_async(dispatch_get_main_queue(), ^{
        [btnUpgradeYesProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
        [btnUpgradeNoProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
        //});
        
        valueChosen = [player getAutoUpgrade];
        //dispatch_async(dispatch_get_main_queue(), ^{
        if (valueChosen == true) {
            [btnUpgradeYesProperty setImage:rowImageSelect forState:UIControlStateNormal];
            [btnUpgradeNoProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
        }else{
            [btnUpgradeYesProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
            [btnUpgradeNoProperty setImage:rowImageSelect forState:UIControlStateNormal];
        }
        [self setBackgroundColor:[UIColor clearColor]];
    });
}

- (IBAction)btnSave:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [player setAutoUpgrade:valueChosen];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (viewControllerDelegate != nil) {
                [viewControllerDelegate backHome];
            }
            [self viewDidUnload];
        });
    });
}

-(void)reSizeScreen{
    int y = 65;
    int x;
    CGRect newFrameSize;
    CGRect mainFrameSize;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation != UIDeviceOrientationLandscapeRight && orientation != UIDeviceOrientationLandscapeLeft) {
        x = (self.frame.size.height)/2-150;
        newFrameSize =  CGRectMake (0, 0, screenWidth, screenHeight);
    }else{
        x = (self.frame.size.height)/2;
        newFrameSize =  CGRectMake (0, 0, screenHeight,screenWidth);
    }
    
    mainFrameSize = CGRectMake (x,y, 322, 342);
   // self.uiViewBackground.frame= newFrameSize;
    self.uiViewMain.frame = mainFrameSize;
}

- (IBAction)btnCancel:(id)sender {
    
    if (viewControllerDelegate != nil) {
        [viewControllerDelegate backHome];
    }
    [self viewDidUnload];
    
}
- (IBAction)btnUpgradeYes:(id)sender {
    [btnUpgradeYesProperty setImage:rowImageSelect forState:UIControlStateNormal];
    [btnUpgradeNoProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
    
    valueChosen = true;
    
}

- (IBAction)btnUpgradeNo:(id)sender {
    [btnUpgradeYesProperty setImage:rowImageUnSelected forState:UIControlStateNormal];
    [btnUpgradeNoProperty setImage:rowImageSelect forState:UIControlStateNormal];
    
    valueChosen = false;
}


-(void)viewDidUnload{
    btnUpgradeYesProperty = nil;
    btnUpgradeNoProperty = nil;
    viewControllerDelegate = nil;
    rowImageUnSelected = nil;
    rowImageSelect = nil;
    valueChosen = nil;
    // [[NSNotificationCenter defaultCenter] removeObserver:self name:ORIENTATION_CHANGE_DEVICE object:nil];
}
@end
