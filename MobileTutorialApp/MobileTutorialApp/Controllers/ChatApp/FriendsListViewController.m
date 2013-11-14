//
//  FriendsListViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//


#import "FriendsListViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "UserCell.h"
#import "UserDetailViewController.h"
#import "VideoCallViewController.h"

@interface FriendsListViewController ()

@property (strong, nonatomic) UIAlertView *callAlert;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) AVAudioPlayer *ringingPlayer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSMutableArray *searchUsers;
//@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *users;
@property (weak, nonatomic)   UITableView *usersTable;

@end

@implementation FriendsListViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:NO];
    NSMutableDictionary *videoChatConfiguration = [[QBSettings videoChatConfiguration] mutableCopy];
    [videoChatConfiguration setObject:@20 forKey:kQBVideoChatCallTimeout];
    [videoChatConfiguration setObject:AVCaptureSessionPresetLow forKey:kQBVideoChatFrameQualityPreset];
    [videoChatConfiguration setObject:@10 forKey:kQBVideoChatVideoFramesPerSecond];
    [QBSettings setVideoChatConfiguration:videoChatConfiguration];
    
    self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
    
    // Start sending chat presence
    //
    [QBChat instance].delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:30 target:[QBChat instance] selector:@selector(sendPresence) userInfo:nil repeats:YES];

    self.delegate = self;
    self.allowsMultipleSelection =  NO;
    NSSet *fields = [NSSet setWithObjects:@"installed", nil];
    self.fieldsForRequest = fields;
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(facebookViewControllerCancelWasPressed:)];
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Call" style:UIBarButtonItemStyleDone target:self action:@selector(facebookViewControllerDoneWasPressed:)];
    
    /*self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Friends", @"Invite Friends", nil]];
    [self.segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    self.segmentedControl.frame = CGRectMake(80, 15, 70, 30);
    [self.segmentedControl sizeToFit];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.view addSubview:self.segmentedControl];*/
    [self loadData];
    [self clearSelection];
}

- (void)viewDidUnload
{
    // release video chat
    //
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    self.videoChat = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private methods.

- (IBAction)segmentedControlValueChanged:(id)sender
{
    if(self.segmentedControl.selectedSegmentIndex == 0) {
        self.allowsMultipleSelection =  NO;
    } else {
        self.allowsMultipleSelection =  YES;
    }
    [self loadData];
    [self clearSelection];
}

#pragma mark - FBFriendPickerDelegate methods

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
   // NSMutableString *text = [[NSMutableString alloc] init];
    for (id<FBGraphUser> user in self.selection) {
        /*if ([text length]) {
            [text appendString:@", "];
        }
        [text appendString:user.name];*/
        //TODO get seleted QBuser and call him/her.
        [QBUsers userWithFacebookID:user.id delegate:self];
    }
}

- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    [self logoutMe];
}

-(BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker shouldIncludeUser:(id<FBGraphUser>)user
{
    BOOL installed;
    if(self.segmentedControl.selectedSegmentIndex == 0)
    {
        installed = [user objectForKey:@"installed"] != nil;

    } else {
        installed = [user objectForKey:@"installed"] == nil;
    }
 return installed;
}


#pragma mark -QuickBlox API queries delegate

- (void)completedWithResult:(Result *)result
{
    // Retrieve Users result
    if([result isKindOfClass:[QBUUserResult class]])
    {
        // Success result
        if (result.success)
        {
            QBUUserResult *selectedUser = (QBUUserResult *)result;
            [User sharedInstance].opponent = selectedUser.user;
            VideoCallViewController *videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
            videoCallViewController.videoChat = self.videoChat;
            self.videoCallViewController = videoCallViewController;
            [self.navigationController pushViewController:videoCallViewController animated:YES];
            // Errors
        }else{
            NSLog(@"Errors=%@", result.errors);
        }
        
    }else if([result isKindOfClass:[QBUUserLogOutResult class]]){
        
		QBUUserLogOutResult *res = (QBUUserLogOutResult *)result;
        
		if(res.success){
		    NSLog(@"LogOut successful.");
            [User sharedInstance].currentQBUser = nil;
            [User sharedInstance].opponent = nil;
            [ApplicationDelegate.session closeAndClearTokenInformation];
            [FBSession setActiveSession:nil];
            [self dismissViewControllerAnimated:YES completion:nil];
		}else{
            NSLog(@"errors=%@", result.errors);
		}
	} else if([result isKindOfClass:[QBUUserResult class]]) {
        
        //TODO retrive opponent and assign in [User sharedInstance].opponent
    }
    
}

#pragma mark Private methods.

- (void)logoutMe
{
    // logout user
    if ([[QBChat instance] isLoggedIn]) {
        [[QBChat instance] unregisterVideoChatInstance: self.videoChat];
        [[QBChat instance] logout];
    }
    [QBUsers logOutWithDelegate:self];
}

- (void)accept
{
    
    if (![self.navigationController.visibleViewController isKindOfClass:[VideoCallViewController class]]) {
        self.videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
        self.videoCallViewController.videoChat = self.videoChat;
        [self.navigationController pushViewController:self.videoCallViewController animated:YES];
    }
    
    // Accept call
    //
    [self.videoChat acceptCall];
    [self.videoCallViewController callAccepted];
    self.ringingPlayer = nil;
}

- (void)hideCallAlert
{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
}

- (void)reject
{
    // Reject call
    [self.videoChat rejectCall];
    [self.videoCallViewController callRejected];
    
    self.ringingPlayer = nil;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate

// Called in case when anyone is calling to you
-(void)chatDidReceiveCallRequestFromUser:(NSUInteger)userID conferenceType:(enum QBVideoChatConferenceType)conferenceType customParameters:(NSDictionary *)customParameters
{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
    [User sharedInstance].opponent = [[QBUUser alloc] init];
    [User sharedInstance].opponent.ID = userID;
    [User sharedInstance].opponent.login = [customParameters objectForKey:@"login"];
    
    //TODO retrive opponent for more information like showing pics
    //[QBUsers userWithID:userID delegate:self];
    
    // show call alert
    if (self.callAlert == nil) {
        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?",[User sharedInstance].opponent.login];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
        [self.callAlert show];
    }
    
    // hide call alert if caller has canceled call
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCallAlert) object:nil];
    [self performSelector:@selector(hideCallAlert) withObject:nil afterDelay:3];
    
    // play call music
    if(self.ringingPlayer == nil){
        NSString *path =[[NSBundle mainBundle] pathForResource:@"ringing" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        self.ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        self.ringingPlayer.delegate = self;
        [self.ringingPlayer setVolume:1.0];
        [self.ringingPlayer play];
    }
}

// Called in case when you are calling to user, but he hasn't answered
-(void)chatCallUserDidNotAnswer:(NSUInteger)userID{
    NSLog(@"chatCallUserDidNotAnswer %d", userID);
    
    [self.videoCallViewController callRejected];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidRejectByUser:(NSUInteger)userID
{
    NSLog(@"chatCallDidRejectByUser %d", userID);
    [self.videoCallViewController callRejected];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Systango VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    [self.videoCallViewController callAccepted];
}

-(void)chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status
{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
        self.ringingPlayer = nil;
        
    }else{
        [self.videoCallViewController callDidStopByUser];
    }
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID {
    
}

- (void)didStartUseTURNForVideoChat{
    NSLog(@"_____TURN_____TURN_____");
}


#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
            // Reject
        case 0:
            [self reject];
            break;
            // Accept
        case 1:
            [self accept];
            break;
            
        default:
            break;
    }
    self.callAlert = nil;
}

@end
