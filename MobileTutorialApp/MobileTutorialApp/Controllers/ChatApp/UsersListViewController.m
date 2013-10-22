//
//  UsersListViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "UsersListViewController.h"
#import "FBService.h"
#import "User.h"
#import "UserCell.h"
#import "UserDetailViewController.h"
#import "VideoCallViewController.h"

@interface UsersListViewController ()

@property (strong, nonatomic) AVAudioPlayer *ringingPlayer;
@property (strong, nonatomic) UIAlertView *callAlert;
@property (strong, nonatomic) NSMutableArray *searchUsers;
@property (strong, nonatomic) NSArray *users;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;

@end

@implementation UsersListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self retrieveUsers];
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload{
     // release video chat
     //
     [[QBChat instance] unregisterVideoChatInstance:self.videoChat];
     self.videoChat = nil;
}


// Retrieve QuickBlox Users
- (void) retrieveUsers{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // retrieve 100 users
    PagedRequest* request = [[PagedRequest alloc] init];
    request.perPage = 100;
	[QBUsers usersWithPagedRequest:request delegate:self];
}

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result
{
    // Retrieve Users result
    if([result isKindOfClass:[QBUUserPagedResult class]])
    {
        // Success result
        if (result.success)
        {
            // update table
            QBUUserPagedResult *usersSearchRes = (QBUUserPagedResult *)result;
            self.users = usersSearchRes.users;
            self.searchUsers = [self.users mutableCopy];
            [self.usersTable reloadData];
            // Errors
        }else{
            NSLog(@"Errors=%@", result.errors);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    }else if([result isKindOfClass:[QBUUserLogOutResult class]]){
        
		QBUUserLogOutResult *res = (QBUUserLogOutResult *)result;
        
		if(res.success){
		    NSLog(@"LogOut successful.");
            self.currentUser = nil;
            [User sharedInstance].currentQBUser = nil;
            [self.navigationController popToRootViewControllerAnimated:YES];
		}else{
            NSLog(@"errors=%@", result.errors);
		}
	}

}


#pragma mark -
#pragma mark TableViewDataSource & TableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*[self.searchBar resignFirstResponder];
    
    // show user details
    detailsController.choosedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    [self presentModalViewController:detailsController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];*/
    
    // show user details
    UserDetailViewController *userDetailViewController = [[UserDetailViewController alloc] initWithNibName:@"UserDetailViewController" bundle:nil];
    userDetailViewController.selectedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    userDetailViewController.usersListViewController = self;
    [self.navigationController pushViewController:userDetailViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchUsers count];
}

// Making table view using custom cells
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";

	UserCell *cell = (UserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) {
		NSArray *nibObjects;
         nibObjects = [[NSBundle mainBundle] loadNibNamed:@"UserCell"
													   owner:self
													 options:nil];
		cell = [nibObjects objectAtIndex:0];
	}

    QBUUser *obtainedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    
    if(obtainedUser.login != nil) {
        cell.userName.text = obtainedUser.login;
    }
    else{
        cell.userName.text = obtainedUser.email;
    }
    
    return cell;
}
- (IBAction)logoutMe:(id)sender {
    // logout
    /*[[User sharedInstance] clearFBAccess];
    [[FBService shared].facebook logout];
    [self.navigationController popViewControllerAnimated:YES];*/
    
    // logout user
    if ([[QBChat instance]isLoggedIn]) {
        [[QBChat instance] unregisterVideoChatInstance: self.videoChat];
        [[QBChat instance] logout];
      }
    [QBUsers logOutWithDelegate:self];
}


- (void)reject{
    // Reject call
    //
    [self.videoChat rejectCall];
    [self.delegate callRejected];
    
    self.ringingPlayer = nil;
}

- (void)accept{

    if (![self.navigationController.visibleViewController isKindOfClass:[VideoCallViewController class]]) {
        VideoCallViewController *videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
        videoCallViewController.usersListViewController = self;
        [self.navigationController pushViewController:videoCallViewController animated:YES];
    }

    // Accept call
    //
    [self.videoChat acceptCall];
    [self.delegate callAccepted];
    self.ringingPlayer = nil;
}

- (void)hideCallAlert{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    self.ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate
//
// VideoChat delegate

// Called in case when anyone is calling to you
-(void)chatDidReceiveCallRequestFromUser:(NSUInteger)userID conferenceType:(enum QBVideoChatConferenceType)conferenceType{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
    //self.callButton.hidden = YES;
    
    // show call alert
    //
    if (self.callAlert == nil) {
        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", [User sharedInstance].currentQBUser.login];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
        [self.callAlert show];
    }
    
    // hide call alert if caller has canceled call
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCallAlert) object:nil];
    [self performSelector:@selector(hideCallAlert) withObject:nil afterDelay:3];
    
    // play call music
    //
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
    
    /* self.callButton.hidden = NO;
     self.ringigngLabel.hidden = YES;
     self.callingActivityIndicator.hidden = YES;
     self.callButton.tag = 101;*/
    [self.delegate callRejected];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidRejectByUser:(NSUInteger)userID {
    NSLog(@"chatCallDidRejectByUser %d", userID);
    
    /*self.callButton.hidden = NO;
     self.ringigngLabel.hidden = YES;
     self.callingActivityIndicator.hidden = YES;
     
     self.callButton.tag = 101;*/
    [self.delegate callRejected];
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Systango VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void)chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    [self.delegate callAccepted];
}

-(void)chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        // self.callButton.hidden = NO;
        
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
        
        //self.ringigngLabel.hidden = YES;
        
        self.ringingPlayer = nil;
        
    }else{
        [self.delegate callDidStopByUser];
    }
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID {
    [self.delegate callDidStartWithUser];
}

- (void)didStartUseTURNForVideoChat{
    NSLog(@"_____TURN_____TURN_____");
}


#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
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
