//
//  LoginViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//


#import "LoginViewController.h"
#import "AppDelegate.h"
#import "FriendsListViewController.h"
#import "Reachability.h"
#import "User.h"
#import "UserDetailViewController.h"
#import "UsersListViewController.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *fbLoginButton;

- (IBAction)loginWithFaceBook:(id)sender;

@end

@implementation LoginViewController

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
    
    [QBAuth createSessionWithDelegate:self];
    
    [ApplicationDelegate.session closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];

    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startApplication)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];*/
    
    if (!ApplicationDelegate.session.isOpen) {
        // create a fresh session object
        ApplicationDelegate.session = [[FBSession alloc] init];
        
        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (ApplicationDelegate.session.state == FBSessionStateCreatedTokenLoaded) {
            // even though we had a cached token, we need to login to make the session usable
            [ApplicationDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
                //[self updateView];
                // and here we make sure to update our UX according to the new session state
                switch (status) {
                    case FBSessionStateClosedLoginFailed:
                        NSLog(@"%@", error.localizedDescription);
                        break;
                    case FBSessionStateOpen:
                    {
                        ApplicationDelegate.session = session;
                        //[self getUserFBProfile];
                    }
                        break;
                    default:
                        break;
                }
            }];
        }
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [self.activityIndicator setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBAction

- (IBAction)loginWithFaceBook:(id)sender {
    
    if (![Reachability internetConnected]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No internet connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (ApplicationDelegate.session.isOpen) {
        // if a user logs out explicitly, we delete any cached token information, and next
        // time they run the applicaiton they will be presented with log in UX again; most
        // users will simply close the app or switch away, without logging out; this will
        // cause the implicit cached-token login to occur on next launch of the application
        [ApplicationDelegate.session closeAndClearTokenInformation];
    }
    
    if (ApplicationDelegate.session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        ApplicationDelegate.session = [[FBSession alloc] init];
    }
    
    // if the session isn't open, let's open it now and present the login UX to the user
    [ApplicationDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
        // and here we make sure to update our UX according to the new session state
        switch (status) {
            case FBSessionStateClosedLoginFailed:
                NSLog(@"Login error : %@", error.localizedDescription);
                break;
            case FBSessionStateOpen:
                NSLog(@"FB Login Success.");
                [self performSelector:@selector(getUserFBProfile) withObject:nil afterDelay:.5];
                break;
            default:
                break;
        }
    }];
    [self startStopActivityIndicator:YES];
}


- (void)getUserFBProfile
{
    if (ApplicationDelegate.session.isOpen) {
        
        [FBSession setActiveSession:ApplicationDelegate.session];
        [[[FBRequest alloc] initWithSession:ApplicationDelegate.session graphPath:@"me"] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error)           {
             if (!error) {
                 NSLog(@"FBUserName= %@ & FBUserId= %@", user.name, user.id);
                 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                 
                 NSLog(@"self.session.accessTokenData.accessToken = %@",ApplicationDelegate.session.accessTokenData.accessToken);
                 [defaults setObject:ApplicationDelegate.session.accessTokenData.accessToken forKey:@"FBAccessTokenKey"];
                 [defaults setObject:user.name forKey:@"FBUserName"];
                 [defaults setObject:user.id forKey:@"FBUserId"];
                 [defaults synchronize];
                 [User sharedInstance].currentQBUser = [[QBUUser alloc] init];
                 [User sharedInstance].currentQBUser.facebookID = user.id;

                 NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
                 NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
                 // Authenticate user
                 [QBUsers logInWithUserLogin:userLogin password:passwordHash delegate:self];
                 // Authenticate user through Facebook
                 //This way working.
                 //[QBUsers logInWithSocialProvider:@"facebook" scope:nil delegate:self];

             }else{
                 NSLog(@"%@", error.localizedDescription);
             }
         }];
    }
}

- (void)createSession
{
    [self createSessionWithDelegate:nil];
}

- (void)createSessionWithDelegate:(id)delegate
{
    //
    // Create extended session request with user authorization
    //
    if([User sharedInstance].currentQBUser){
        QBASessionCreationRequest *extendedAuthRequest = [QBASessionCreationRequest request];
        extendedAuthRequest.userLogin = [User sharedInstance].currentQBUser.facebookID;
        extendedAuthRequest.userPassword = [User sharedInstance].currentQBUser.facebookID;
        [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
    }
    
}

- (void)startApplication
{
    // QuickBlox application autorization
    [NSTimer scheduledTimerWithTimeInterval:60*60*2-600 // Expiration date of access token is 2 hours. Repeat request for new token every 1 hour and 50 minutes.
                                     target:self
                                   selector:@selector(createSession)
                                   userInfo:nil
                                    repeats:YES];
    
    [self createSessionWithDelegate:self];
	
}

- (void)startStopActivityIndicator:(BOOL)start
{
    [self.activityIndicator setHidden:!start];
    self.fbLoginButton.userInteractionEnabled = !start;
    start ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
}


#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
-(void)completedWithResult:(Result *)result  context:(void *)contextInfo
{
    if([result isKindOfClass:[QBUUserLogInResult class]]){
		
        // Success result
        if(result.success){
            // save current user
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            [User sharedInstance].currentQBUser = res.user;
            
            NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
            [User sharedInstance].currentQBUser.login = userLogin;
            //[User sharedInstance].currentQBUser.password = (__bridge NSString *)contextInfo;
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
            [User sharedInstance].currentQBUser.password = passwordHash;
            // Login to Chat
            [QBChat instance].delegate = self;
            [[QBChat instance] loginWithUser:[User sharedInstance].currentQBUser];
            
            // Errors
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errors"
                                                            message:[result.errors description]
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles: nil];
            alert.tag = 1;
            [alert show];
            [self startStopActivityIndicator:NO];
        }
    }
}

-(void)completedWithResult:(Result *)result{
    
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        
        // Success result
        if(result.success){
            
            NSString *token = ((QBAAuthSessionCreationResult *)result).session.token;
            NSLog(@"token++++++++%@",token);
        }
        
    } else if([result isKindOfClass:[QBUUserLogInResult class]]){
		
        // Success result
        if(result.success){

            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            [User sharedInstance].currentQBUser = res.user;
            
            NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
            [User sharedInstance].currentQBUser.login = userLogin;
            //[User sharedInstance].currentQBUser.password = (__bridge NSString *)contextInfo;
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
            [User sharedInstance].currentQBUser.password = passwordHash;
            // Login to Chat
            [QBChat instance].delegate = self;
            [[QBChat instance] loginWithUser:[User sharedInstance].currentQBUser];
            
        }
        else if(401 == result.status){
            // Register new user
            // Create QBUUser entity
            QBUUser *user = [User sharedInstance].currentQBUser;
            NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
            user.login = userLogin;
            user.password = passwordHash;
            user.facebookID = userLogin;
            user.tags = [NSMutableArray arrayWithObject:@"Systango"];
            // Create user
            [QBUsers signUp:user delegate:self];
        }
        // Errors
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Errors"
                                                            message:[result.errors description]
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles: nil];
            [alert show];
            [self startStopActivityIndicator:NO];
        }
    }
    else if([result isKindOfClass:[QBUUserResult class]]){
        // Success result
        if(result.success){
            //TODO login to QBchat
        }
    }
}

#pragma mark -
#pragma mark QBChatDelegate

-(void)chatDidLogin
{
    FriendsListViewController *friendsListViewController = [[FriendsListViewController alloc] init];
    [self.navigationController pushViewController:friendsListViewController animated:YES];
    [self startStopActivityIndicator:NO];
}

- (void)chatDidNotLogin{
    [ApplicationDelegate.session closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Chat Authentification Fail"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    [self startStopActivityIndicator:NO];
}


@end

