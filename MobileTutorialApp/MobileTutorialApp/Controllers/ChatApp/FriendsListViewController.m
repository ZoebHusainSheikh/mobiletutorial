//
//  FriendsListViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "FriendsListViewController.h"
#import "AppDelegate.h"
#import "Common.h"
#import "Constants.h"
#import "LoginViewController.h"
#import "Reachability.h"
#import "User.h"
#import "UserCell.h"
#import "UserDetailViewController.h"
#import "VideoCallViewController.h"

@interface FriendsListViewController ()

@property (strong, nonatomic) UIAlertView *callAlert;
@property (strong, nonatomic) NSString *friendsIdString;
@property (strong, nonatomic) AVAudioPlayer *ringingPlayer;
@property (strong, nonatomic) NSMutableArray *searchUsers;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *users;
@property (weak, nonatomic)   UITableView *usersTable;

@end

@implementation FriendsListViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.image = [UIImage imageNamed:@"friends"];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    self.allowsMultipleSelection =  NO;
    self.fieldsForRequest = [NSSet setWithObjects:@"installed", nil];
    [self loadData];

    NSMutableDictionary *videoChatConfiguration = [[QBSettings videoChatConfiguration] mutableCopy];
    [videoChatConfiguration setObject:@20 forKey:kQBVideoChatCallTimeout];
    [videoChatConfiguration setObject:AVCaptureSessionPresetLow forKey:kQBVideoChatFrameQualityPreset];
    [videoChatConfiguration setObject:@10 forKey:kQBVideoChatVideoFramesPerSecond];
    [QBSettings setVideoChatConfiguration:videoChatConfiguration];
    
    self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
    
    // Start sending chat presence
    [QBChat instance].delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(sendPresence) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self clearSelection];
}

- (void)viewDidUnload
{
    // release video chat
    [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
    self.videoChat = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark IBAction methods

- (IBAction)segmentedControlValueChanged:(id)sender
{
    self.allowsMultipleSelection = self.segmentedControl.selectedSegmentIndex != 0;
    self.doneButton.enabled = self.segmentedControl.selectedSegmentIndex == 1;
    [self updateView];
}

#pragma mark - FBFriendPickerDelegate methods

- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    if (![Reachability internetConnected]){
        [Common showNetworkErrorAlert];
        return;
    }
    // logout user
    [self clearSelection];
    if ([[QBChat instance] isLoggedIn]) {
        [[QBChat instance] unregisterVideoChatInstance: self.videoChat];
        [[QBChat instance] logout];
    }
    [QBUsers logOutWithDelegate:self];
    
    [User sharedInstance].currentQBUser = nil;
    [User sharedInstance].opponent = nil;
    [ApplicationDelegate.session closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    if (![Reachability internetConnected]){
        [Common showNetworkErrorAlert];
        return;
    }
    
    if (self.segmentedControl.selectedSegmentIndex == 1){
        NSMutableString *text = [[NSMutableString alloc] init];
        // we pick up the users from the selection, and create a string that we use to tag them in post
        if (self.selection.count == 0){
            [Common showAlertWithTitle:@"Hey!" description:@"Please select friends from the list before Inviting."];
            return ;
        }
        for (id<FBGraphUser> user in self.selection) {
            if ([text length]) {
                [text appendString:@","];
            }
            [text appendString:user.id];
        }
        self.friendsIdString = text;
        
        //To avoid reauthorize error
        FBSession.activeSession = ApplicationDelegate.session;
        if ([FBSession activeSession].isOpen)
        {
            //[FBSession openActiveSessionWithAllowLoginUI:NO];
            if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
                // if we don't already have the permission, then we request it now
                [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
                                                      defaultAudience:FBSessionDefaultAudienceFriends
                                                    completionHandler:^(FBSession *session, NSError *error) {
                                                        if (!error) {
                                                            [self fbPostSettings];
                                                        }else{
                                                            NSLog(@"Facebook Error:%@", error.localizedDescription);
                                                            [Common showAlertWithTitle:@"Facebook Error" description:error.localizedDescription];
                                                        }
                                                        //For this example, ignore errors (such as if user cancels).
                                                    }];
            } else {
                [self fbPostSettings];
            }
        }
    }
}

- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker
{
    if (![Reachability internetConnected] && friendPicker.selection.count){
        [self clearSelection];
        [Common showNetworkErrorAlert];
        return;
    }
    //Get QBuser from selected facebook user
    if ((self.segmentedControl.selectedSegmentIndex == 0) && friendPicker.selection.count) {
        [QBUsers userWithFacebookID:[[friendPicker.selection objectAtIndex:0] id] delegate:self];
    }
}

#pragma mark -
#pragma mark QBChatDelegate

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker shouldIncludeUser:(id<FBGraphUser>)user
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

- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error
{
    NSLog(@"%@",error);
    [Common showAlertWithTitle:@"Error" description:error.description];
    [self facebookViewControllerCancelWasPressed:nil];
}

#pragma mark Private methods.

- (void)accept
{
    if (![self.navigationController.visibleViewController isKindOfClass:[VideoCallViewController class]]) {
        self.videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
        self.videoCallViewController.videoChat = self.videoChat;
        [self presentViewController:self.videoCallViewController animated:YES completion:nil];
    }
    // Accept call
    [self.videoChat acceptCall];
    [self.videoCallViewController callAccepted];
    self.ringingPlayer = nil;
    
   /* if (self.videoCallViewController.isViewLoaded && self.videoCallViewController.view.window) {
        // videoCallViewController is visible dismiss it
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    self.videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
    self.videoCallViewController.videoChat = self.videoChat;
    [self presentViewController:self.videoCallViewController animated:YES completion:^{
        // Accept call
        [self.videoChat acceptCall];
        [self.videoCallViewController callAccepted];
        self.ringingPlayer = nil;
    }];*/
}

- (void)fbPostSettings
{
    NSDictionary * facebookParams = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      @"https://www.google.co.in/",     @"link",
                                     @"Video Chat App",                 @"name",
                                      @"Your friend has invited you to join Video chat app!", @"caption",
                                      
                                      @"",                              @"description",
                                      self.friendsIdString,             @"tags",
                                      @"155021662189",                  @"place",
                                      @"",                              @"picture",
                                                                                    nil];
    [FBRequestConnection startWithGraphPath:@"me/feed"
                                 parameters:facebookParams
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              
                              if (error) {
                                  NSLog(@"Facebook Error:%@", error.localizedDescription);
                                  [Common showAlertWithTitle:@"Facebook Error" description:error.localizedDescription];
                              } else {
                                 NSLog(@"Success Posted action and id = %@",self.friendsIdString);
                                 UIAlertView *popupAlert = [[UIAlertView alloc] initWithTitle:@"Your FB friends are notified on their timeline." message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                  [popupAlert show];
                                  [self clearSelection];
                              }
                              
                          }];
    
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

- (void)sendPresence
{
    if (![[QBChat instance] sendPresence]) {
       // TODO relogin in chat if needed
    }
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    self.ringingPlayer = nil;
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
            
            //Check user online status
            NSInteger currentTimeInterval = [[NSDate date] timeIntervalSince1970];
            NSInteger userLastRequestAtTimeInterval   = [[selectedUser.user lastRequestAt] timeIntervalSince1970];
            // if user didn't do anything last 5 minutes (5*60 seconds)
            if((currentTimeInterval - userLastRequestAtTimeInterval) <= 5*60){
                // user is online now
                [User sharedInstance].opponent = selectedUser.user;
                VideoCallViewController *videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
                videoCallViewController.videoChat = self.videoChat;
                self.videoCallViewController = videoCallViewController;
                [self presentViewController:self.videoCallViewController animated:YES completion:nil];
            } else {
                // user is offline now
                NSString *message = [NSString stringWithFormat:@"%@ is now offline.", selectedUser.user.fullName];
                [Common showAlertWithTitle:@"Offline" description:message];
                [self clearSelection];
            }
            // Errors
        }else{
            NSLog(@"Errors=%@", result.errors);
            [Common showAlertWithTitle:QBError  description:@"This is user has been removed."];
        }
        
    }else if([result isKindOfClass:[QBUUserLogOutResult class]]){
        
		QBUUserLogOutResult *res = (QBUUserLogOutResult *)result;
        
		if(res.success){
		    NSLog(@"Successfully Logout.");
		}else{
            NSLog(@"errors=%@", result.errors);
            [Common showAlertWithTitle:QBError description:result.errors.description];

		}
	}
}

#pragma mark -
#pragma mark QBChatDelegate

// Called in case when anyone is calling to you
-(void)chatDidReceiveCallRequestFromUser:(NSUInteger)userID conferenceType:(enum QBVideoChatConferenceType)conferenceType customParameters:(NSDictionary *)customParameters
{
    NSLog(@"%s , userID: %d",__FUNCTION__,userID);
    if (![User sharedInstance].opponent) {
        [User sharedInstance].opponent = [[QBUUser alloc] init];
    }
    [User sharedInstance].opponent.ID = userID;
    [User sharedInstance].opponent.fullName = [customParameters objectForKey:@"name"];
    [User sharedInstance].opponent.facebookID = [customParameters objectForKey:@"facebookID"];

    // show call alert
    if (self.callAlert == nil) {
        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?",[User sharedInstance].opponent.fullName];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
        //self.callAlert.delegate = self;
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
-(void)chatCallUserDidNotAnswer:(NSUInteger)userID
{
    NSLog(@"%s , userID: %d",__FUNCTION__,userID);
    
    [self.videoCallViewController callRejected];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidRejectByUser:(NSUInteger)userID
{
    NSLog(@"%s , userID: %d",__FUNCTION__,userID);
    [self.videoCallViewController callRejected];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Systango VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidAcceptByUser:(NSUInteger)userID
{
    NSLog(@"%s , userID: %d",__FUNCTION__,userID);
    [self.videoCallViewController callAccepted];
}

-(void)chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status
{
    NSLog(@"%s, %d purpose %@",__FUNCTION__, userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
        self.ringingPlayer = nil;
        
    }else{
        [self.videoCallViewController callDidStopByUser];
    }
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID
{
    NSLog(@"%s , userID: %d",__FUNCTION__,userID);
}

- (void)didStartUseTURNForVideoChat
{
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"_____TURN_____TURN_____");
}

- (void)chatTURNServerDidDisconnect
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)chatTURNServerdidFailWithError:(NSError *)error
{
    NSLog(@"%s ,error:%@  ",__FUNCTION__,error);
}

- (void)chatDidEexceedWriteAudioQueueMaxOperationsThresholdWithCount:(int)operationsInQueue
{
    NSLog(@"%s",__FUNCTION__);
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
