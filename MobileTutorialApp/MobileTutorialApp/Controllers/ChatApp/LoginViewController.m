//
//  LoginViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//


#import "LoginViewController.h"
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
    //[QBAuth createSessionWithDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startApplication)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
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
    
    [QBUsers logInWithSocialProvider:@"facebook" scope:nil delegate:self];
    [self startStopActivityIndicator:YES];
}

#pragma mark Private methods.

- (void)createSession
{
    [self createSessionWithDelegate:nil];
}

- (void)createSessionWithDelegate:(id)delegate{
  	// Create extended application authorization request (for push notifications)
	/*QBASessionCreationRequest *extendedAuthRequest = [[QBASessionCreationRequest alloc] init];
     
     if([User sharedInstance].currentQBUser){
     extendedAuthRequest.userLogin = [User sharedInstance].currentQBUser.facebookID;
     extendedAuthRequest.userPassword = [NSString stringWithFormat:@"%u", [[User sharedInstance].currentQBUser.password hash]];
     }
     // QuickBlox application authorization
     [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:delegate];*/
    
    
    
    // Your app connects to QuickBlox server here.
    //
    // Create extended session request with user authorization
    //
    QBASessionCreationRequest *extendedAuthRequest = [QBASessionCreationRequest request];
    extendedAuthRequest.userLogin = [User sharedInstance].currentQBUser.facebookID;
    extendedAuthRequest.userPassword = [NSString stringWithFormat:@"%u", [[User sharedInstance].currentQBUser.password hash]];
    [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
    
    
}

- (void)startApplication{
    
    // QuickBlox application autorization
    
    [NSTimer scheduledTimerWithTimeInterval:60*60*2-600 // Expiration date of access token is 2 hours. Repeat request for new token every 1 hour and 50 minutes.
                                     target:self
                                   selector:@selector(createSession)
                                   userInfo:nil
                                    repeats:YES];
    
    [self createSessionWithDelegate:self];
	
}

- (void)startStopActivityIndicator:(BOOL)start{
    [self.activityIndicator setHidden:!start];
    self.fbLoginButton.userInteractionEnabled = !start;
    start ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
}


#pragma mark -
#pragma mark QBActionStatusDelegate

// QuickBlox API queries delegate
-(void)completedWithResult:(Result *)result  context:(void *)contextInfo
{
    
    // QuickBlox User authentication result
    if([result isKindOfClass:[QBUUserLogInResult class]]){
		
        // Success result
        if(result.success){
            
            // save current user
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            [User sharedInstance].currentQBUser = res.user;
            [User sharedInstance].currentQBUser.password = (__bridge NSString *)contextInfo;
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
    // QuickBlox User authentication result
    if([result isKindOfClass:[QBUUserLogInResult class]]){
		
        // Success result
        if(result.success){
            
            // If we are authenticating through Twitter/Facebook - we use token as user's password for Chat module
            [self completedWithResult:result context:(__bridge void *)([BaseService sharedService].token)];
        }
        else if(401 == result.status){
            
            // Register new user
            // Create QBUUser entity
            QBUUser *user = [[QBUUser alloc] init];
            NSString *userLogin = [User sharedInstance].currentQBUser.facebookID;
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [([BaseService sharedService].token) hash]];
            
            user.login = userLogin;
            user.password = passwordHash;
            user.facebookID = [User sharedInstance].currentQBUser.facebookID;
            user.tags = [NSArray arrayWithObject:@"Video Chat"];
            
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
}

#pragma mark
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    if(alertView.tag == 1){
//        
//    }
}

#pragma mark -
#pragma mark QBChatDelegate

-(void)chatDidLogin
{
    
    UsersListViewController *usersListViewController = [[UsersListViewController alloc] initWithNibName:@"UsersListViewController" bundle:nil];
    [self.navigationController pushViewController:usersListViewController animated:YES];
    [self startStopActivityIndicator:NO];
}

- (void)chatDidNotLogin{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Chat Authentification Fail"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    //alert.tag = 1;
    [alert show];
    [self startStopActivityIndicator:NO];
}


@end
