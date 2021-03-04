//
//  AutoUpgradeController.h
//  voco
//
//  Created by David Ramirez on 10/4/12.
//  Copyright (c) 2012 com.navvo.ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Zone.h"
#import "VocoConstants.h"
#import "ViewController.h"


@protocol ViewControllerDelegate <NSObject>
-(void)backHome;
@end

@interface AutoUpgradeController : UIView{
    Zone *player;
    
@private
    id<ViewControllerDelegate> viewControllerDelegate;
    
}




//Protocol Property
@property (strong,nonatomic) id <ViewControllerDelegate> viewControllerDelegate;


@property (weak, nonatomic) IBOutlet UIButton *btnUpgradeYesProperty;
@property (weak, nonatomic) IBOutlet UIButton *btnUpgradeNoProperty;
@property (weak, nonatomic) IBOutlet UIView *uiViewBackground;
@property (weak, nonatomic) IBOutlet UIView *uiViewMain;
@property (weak, nonatomic) IBOutlet UIButton *btnSaveProperty;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelProperty;
@property (strong, nonatomic) IBOutlet UILabel *lblTitle;
@property (strong, nonatomic) IBOutlet UILabel *lblMessage;
@property (strong, nonatomic) IBOutlet UILabel *lblAutomaticYes;
@property (strong, nonatomic) IBOutlet UILabel *lblAutomaticNo;



- (IBAction)btnSave:(id)sender;
- (IBAction)btnCancel:(id)sender;
- (IBAction)btnUpgradeYes:(id)sender;
- (IBAction)btnUpgradeNo:(id)sender;
- (void)loadScreen:(Zone *)selectedPlayer;

@end
