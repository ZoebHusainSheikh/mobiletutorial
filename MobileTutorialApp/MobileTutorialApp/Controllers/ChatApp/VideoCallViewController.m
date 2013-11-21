//
//  VideoCallViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "VideoCallViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "User.h"

@interface VideoCallViewController ()

@property (weak ,nonatomic) IBOutlet UIButton *callButton;
@property (weak ,nonatomic) IBOutlet UIActivityIndicatorView *callingActivityIndicator;
@property (weak ,nonatomic) IBOutlet UIImageView *myVideoView;
@property (weak ,nonatomic) IBOutlet UINavigationBar *navBar;
@property (nonatomic, weak) IBOutlet UIImageView *opponentVideoView;
@property (weak ,nonatomic) IBOutlet FBProfilePictureView *opponentProfilePictureView;
@property (weak ,nonatomic) IBOutlet UILabel *ringigngLabel;

- (IBAction)call:(id)sender;

@end

@implementation VideoCallViewController

#pragma mark init method

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.opponentVideoView.layer.borderWidth = 1;
    self.opponentVideoView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.opponentVideoView.layer.cornerRadius = 5;
    self.videoChat.viewToRenderOpponentVideoStream = self.opponentVideoView;
    self.videoChat.viewToRenderOwnVideoStream = self.myVideoView;
    [self videoCallSetUp];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBAction methods

- (IBAction)backButtonPressed:(id)sender
{
    [self.videoChat finishCall];
    [User sharedInstance].opponent = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)call:(id)sender
{
    // Call
    if(self.callButton.tag == 101) {
        // Call user by ID
        [self.videoChat callUser:[[NSNumber numberWithInt:[User sharedInstance].opponent.ID] integerValue] conferenceType:QBVideoChatConferenceTypeAudioAndVideo customParameters:[NSDictionary dictionaryWithObjectsAndKeys:[User sharedInstance].currentQBUser.fullName, @"name", [User sharedInstance].currentQBUser.facebookID, @"facebookID", nil]];
        self.callButton.tag = 102;
        self.callButton.hidden = YES;
        self.ringigngLabel.text = @"Calling...";
        self.ringigngLabel.hidden = NO;
        self.callingActivityIndicator.hidden = NO;
        self.navBar.userInteractionEnabled = NO;
        
    }else {
        // Finish call
        [self.videoChat finishCall];
        self.callButton.tag = 101;
        self.myVideoView.hidden = YES;
        self.navBar.userInteractionEnabled = YES;
        self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
        self.opponentVideoView.layer.borderWidth = 1;
        self.callButton.selected = NO;
        self.opponentProfilePictureView.hidden = NO;
        self.opponentVideoView.hidden = YES;
    }
}

#pragma mark Public methods.

- (void)videoCallSetUp
{
    NSLog(@"%s",__FUNCTION__);
    self.opponentProfilePictureView.profileID = [User sharedInstance].opponent.facebookID;
    self.navBar.topItem.title = [User sharedInstance].opponent.fullName;
}

- (void)callAccepted
{
    NSLog(@"%s",__FUNCTION__);
    [self videoCallSetUp];
    self.opponentProfilePictureView.hidden = YES;
    self.opponentVideoView.hidden = NO;
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    self.callButton.hidden = NO;
    self.callButton.tag = 102;
    self.opponentVideoView.layer.borderWidth = 0;
    self.myVideoView.hidden = NO;
    self.callButton.selected = YES;
}

- (void)callDidStopByUser
{
    NSLog(@"%s",__FUNCTION__);
    self.myVideoView.hidden = YES;
    self.navBar.userInteractionEnabled = YES;
    self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
    self.opponentVideoView.layer.borderWidth = 1;
    self.callButton.hidden = NO;
    self.callButton.tag = 101;
    self.callButton.selected = NO;
    self.callingActivityIndicator.hidden = YES;
    self.ringigngLabel.hidden = YES;
    self.opponentProfilePictureView.hidden = NO;
    self.opponentVideoView.hidden = YES;
}

- (void)callRejected
{
    NSLog(@"%s",__FUNCTION__);
    self.callButton.hidden = NO;
    self.navBar.userInteractionEnabled = YES;
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    self.callButton.tag = 101;
}

@end
