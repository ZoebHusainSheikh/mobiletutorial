//
//  LoginViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "ChatViewController.h"
#import "FriendsListViewController.h"
#import "Reachability.h"
#import "User.h"
#import "UserDetailViewController.h"
#import "UserProfileViewController.h"
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

    //TODO handle QBsession
    /*[[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(startApplication)
     name:UIApplicationDidBecomeActiveNotification object:nil];*/
    if ([Reachability internetConnected]) {
        [QBAuth createSessionWithDelegate:self];
        if (!ApplicationDelegate.session.isOpen) {
            [self showLoginButton:NO];
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
                    
                    // and here we make sure to update our UX according to the new session state
                    if (error) {
                        NSLog(@"Login error : %@", error.localizedDescription);
                        [self showLoginButton:YES];
                    } else {
                        switch (status) {
                            case FBSessionStateClosedLoginFailed:
                                NSLog(@"%@", error.localizedDescription);
                                break;
                            case FBSessionStateOpen:
                                [self getUserFBProfile];
                                break;
                            default:
                                break;
                        }
                    }
                }];
            } else {
                [self showLoginButton:YES];
            }
        }
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark IBAction methods

- (IBAction)loginWithFaceBook:(id)sender
{
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
    } else {
        if (ApplicationDelegate.session.state != FBSessionStateCreated) {
            // Create a new, logged out session.
            ApplicationDelegate.session = [[FBSession alloc] init];
        }
        
        // if the session isn't open, let's open it now and present the login UX to the user
        [ApplicationDelegate.session openWithCompletionHandler:^(FBSession *session,
                                                                 FBSessionState status,
                                                                 NSError *error) {
            // and here we make sure to update our UX according to the new session state
            if (error) {
                NSLog(@"Login error : %@", error.localizedDescription);
                [self showLoginButton:NO];
            } else {
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
            }
        }];
    }
    [self showLoginButton:NO];
}

- (void)getUserFBProfile
{
    if (ApplicationDelegate.session.isOpen) {
        
        [FBSession setActiveSession:ApplicationDelegate.session];
        [[[FBRequest alloc] initWithSession:ApplicationDelegate.session graphPath:@"me"] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSMutableDictionary<FBGraphUser> *user, NSError *error)           {
             if (!error) {
                 NSLog(@"FBUserName= %@ & FBUserId= %@", user.name, user.id);
                 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                 
                 NSLog(@"self.session.accessTokenData.accessToken = %@",ApplicationDelegate.session.accessTokenData.accessToken);
                 //[defaults setObject:ApplicationDelegate.session.accessTokenData.accessToken forKey:@"FBAccessTokenKey"];
                 //TODO do not save facebook username and id remove it.
                 [defaults setObject:user.name forKey:@"FBUserName"];
                 [defaults setObject:user.id forKey:@"FBUserId"];
                 [defaults synchronize];
                 [User sharedInstance].currentQBUser = [[QBUUser alloc] init];
                 [User sharedInstance].currentQBUser.facebookID = user.id;
                 [User sharedInstance].currentFBUser = user;
                 NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
                 NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
                 // Authenticate user
                 [QBUsers logInWithUserLogin:userLogin password:passwordHash delegate:self];
             }else{
                 NSLog(@"%@", error.localizedDescription);
                 [self showLoginButton:YES];
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
    // Create extended session request with user authorization
    if([User sharedInstance].currentQBUser){
        QBASessionCreationRequest *extendedAuthRequest = [QBASessionCreationRequest request];
        extendedAuthRequest.userLogin = [User sharedInstance].currentQBUser.facebookID;
        extendedAuthRequest.userPassword = [User sharedInstance].currentQBUser.facebookID;
        [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
    }
}

- (void)loginToQBChat:(Result *)result
{
    QBUUserLogInResult *res = (QBUUserLogInResult *)result;
    [User sharedInstance].currentQBUser = res.user;
    NSString *userLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBUserId"];
    [User sharedInstance].currentQBUser.login = userLogin;
    NSString *passwordHash = [NSString stringWithFormat:@"%u", [userLogin hash]];
    [User sharedInstance].currentQBUser.password = passwordHash;
    // Login to Chat
    [QBChat instance].delegate = self;
    [[QBChat instance] loginWithUser:[User sharedInstance].currentQBUser];
}


- (void)showLoginButton:(BOOL)show
{
    self.fbLoginButton.hidden = !show;
    show ? [self.activityIndicator stopAnimating] : [self.activityIndicator startAnimating];
}


- (void)showTabBarController
{
    // Create a tabbar controller and an array to contain the view controllers
    self.tabBarController = [[UITabBarController alloc] init];
    
    //add FriendsListViewController on tab

    FriendsListViewController *friendsListViewController = [[FriendsListViewController alloc] initWithNibName:@"FriendsListViewController" bundle:nil];
    friendsListViewController.title = @"Friends";

    //add ChatViewController on tab
    ChatViewController *chatViewController = [[ChatViewController alloc] initWithNibName:@"ChatViewController" bundle:nil];
    chatViewController.title = @"Chat";
    
    //add UserProfileViewController on tab
    UserProfileViewController *userProfileViewController = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil];
    userProfileViewController.title = @"Me";
    
    NSArray* controllers = [NSArray arrayWithObjects:friendsListViewController, chatViewController, userProfileViewController, nil];
    self.tabBarController.viewControllers = controllers;
    [self presentViewController:self.tabBarController animated:YES completion:nil];
    [self showLoginButton:YES];
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

#pragma mark -
#pragma mark QBActionStatusDelegate

-(void)completedWithResult:(Result *)result
{
    
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        
        // Success result
        if(result.success){
            
            NSString *token = ((QBAAuthSessionCreationResult *)result).session.token;
            NSLog(@"QBSessiontoken++++++++%@",token);
        }
        
    } else if([result isKindOfClass:[QBUUserLogInResult class]]){
		
        // Success result
        if(result.success){
            [self loginToQBChat:result];
        }
        else if(401 == result.status){
            // Register new user
            // Create QBUUser entity
            QBUUser *user = [User sharedInstance].currentQBUser;
            NSMutableDictionary *fbUser = [User sharedInstance].currentFBUser;
            user.facebookID = [fbUser objectForKey:@"id"];
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [user.facebookID hash]];
            user.fullName = [fbUser objectForKey:@"name"];
            user.login = [fbUser objectForKey:@"id"];
            user.password = passwordHash;
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
            [self showLoginButton:YES];
        }
    }
    else if([result isKindOfClass:[QBUUserResult class]]){
        if(result.success){
            [self loginToQBChat:result];
        }
    }
}

#pragma mark -
#pragma mark QBChatDelegate

-(void)chatDidLogin
{
    [self showTabBarController];
}

- (void)chatDidNotLogin
{
    [ApplicationDelegate.session closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Chat Authentification Fail"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    [self showLoginButton:YES];
}

@end

