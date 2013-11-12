//
//  VideoCallViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "VideoCallViewController.h"
#import "User.h"

@interface VideoCallViewController ()

@property (nonatomic, weak) IBOutlet UIButton *callButton;
@property (nonatomic, weak) IBOutlet UILabel *ringigngLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *callingActivityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *opponentVideoView;
@property (nonatomic, weak) IBOutlet UIImageView *myVideoView;
@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;

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
    
    //[self.navigationController.navigationBar setHidden:YES];
    [self.callButton setTitle:@"Call" forState:UIControlStateNormal];

    self.opponentVideoView.layer.borderWidth = 1;
    self.opponentVideoView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.opponentVideoView.layer.cornerRadius = 5;
    // Setup video chat
    self.videoChat.viewToRenderOpponentVideoStream = self.opponentVideoView;
    self.videoChat.viewToRenderOwnVideoStream = self.myVideoView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navBar.topItem.title = [User sharedInstance].opponent.login;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBAction

- (IBAction)backButtonPressed:(id)sender
{
    [self.videoChat finishCall];
    [User sharedInstance].opponent = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)call:(id)sender
{
    // Call
    if(self.callButton.tag == 101) {
        // Call user by ID
       [self.videoChat callUser:[[NSNumber numberWithInt:[User sharedInstance].opponent.ID] integerValue] conferenceType:QBVideoChatConferenceTypeAudioAndVideo customParameters:[NSDictionary dictionaryWithObject:[User sharedInstance].opponent.login forKey:@"login"]];
       
        self.callButton.tag = 102;
        self.callButton.hidden = YES;
        self.ringigngLabel.hidden = NO;
        self.ringigngLabel.text = @"Calling...";
        self.callingActivityIndicator.hidden = NO;
        self.navBar.userInteractionEnabled = NO;
        
    }else {
        // Finish call
        [self.videoChat finishCall];
        
        self.callButton.tag = 101;
        self.myVideoView.hidden = YES;
        self.navBar.userInteractionEnabled = YES;
        self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
        [self.callButton setTitle:@"Call" forState:UIControlStateNormal];
        self.opponentVideoView.layer.borderWidth = 1;
    }
}

#pragma mark Public methods.

- (void)callAccepted
{
    self.ringigngLabel.hidden = YES;
    self.callButton.hidden = NO;
    [self.callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    self.callButton.tag = 102;
    self.opponentVideoView.layer.borderWidth = 0;
    self.myVideoView.hidden = NO;
}


- (void)callDidStopByUser
{
    self.myVideoView.hidden = YES;
    self.navBar.userInteractionEnabled = YES;
    self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
    self.opponentVideoView.layer.borderWidth = 1;
    [self.callButton setTitle:@"Call" forState:UIControlStateNormal];
    self.callButton.tag = 101;
}


- (void)callRejected
{
    self.callButton.hidden = NO;
    self.navBar.userInteractionEnabled = YES;
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    self.callButton.tag = 101;
}

@end
