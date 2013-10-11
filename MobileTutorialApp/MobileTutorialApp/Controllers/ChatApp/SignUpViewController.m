//
//  SignUpViewController.m
//  MobileTutorialApp
//
//  Created by MAC1 on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "SignUpViewController.h"

// inner
#import "Constants.h"
#import "User.h"
#import "Definitions.h"
//#import "FBService.h"

// categories
//#import "UIImage+ImageExtension.h"
#import "NSArray+convert.h"
//#import "NSString+Additions.h"
//#import "UIColor+hex.h"
#import "NSObject+performer.h"
#import "Reachability.h"
#import "NumberToLetterConverter.h"
#import "UsersListViewController.h"



@interface SignUpViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic) BOOL openedAtStartApp;

- (IBAction)login:(id)sender;
- (void)showLoginButton:(BOOL)isShow;
- (void)startApplication;

@end

@implementation SignUpViewController

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
    self.navigationItem.title = @"Sign Up";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startApplication)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startApplication{
    
    // QuickBlox application autorization
    if(self.openedAtStartApp){
		
        [self.activityIndicator startAnimating];
		
		[NSTimer scheduledTimerWithTimeInterval:60*60*2-600 // Expiration date of access token is 2 hours. Repeat request for new token every 1 hour and 50 minutes.
                                         target:self
                                       selector:@selector(createSession)
                                       userInfo:nil
                                        repeats:YES];
        
        [self createSessionWithDelegate:self];
		
    }else{
        // show Login & Registrations buttons
        [self.activityIndicator stopAnimating];
        
        [self showLoginButton:YES];
    }
    
}

- (void)showLoginButton:(BOOL)isShow{
    self.loginButton.hidden = !isShow;
}

- (void)createSessionWithDelegate:(id)delegate{
  	// Create extended application authorization request (for push notifications)
	QBASessionCreationRequest *extendedAuthRequest = [[QBASessionCreationRequest alloc] init];
	extendedAuthRequest.devicePlatorm = DevicePlatformiOS;
	extendedAuthRequest.deviceUDID = [[UIDevice currentDevice] uniqueIdentifier];
    if([User sharedInstance].currentFBUser){
        
        extendedAuthRequest.userLogin = [[NumberToLetterConverter instance] convertNumbersToLetters:[[User sharedInstance].currentFBUser objectForKey:kId]];
        extendedAuthRequest.userPassword = [NSString stringWithFormat:@"%u", [[[User sharedInstance].currentFBUser objectForKey:kId] hash]];
    }
	
	// QuickBlox application authorization
	[QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:delegate];
}

- (void)createSession
{
    [self createSessionWithDelegate:nil];
}

- (void)viewDidUnload{
    self.activityIndicator = nil;
    self.loginButton = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Login action
- (IBAction)login:(id)sender{
    
    if (![Reachability internetConnected]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No internet connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    // Auth in FB
    NSArray *params = [[NSArray alloc] initWithObjects:@"user_checkins", @"user_location", @"friends_checkins",
                       @"friends_location", @"friends_status", @"read_mailbox",@"photo_upload",@"read_stream",
                       @"publish_stream", @"user_photos", @"xmpp_login", @"user_about_me", nil];
    [[FBService shared].facebook setSessionDelegate:self];
    [[FBService shared].facebook authorize:params];
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
    NSLog(@"fbDidLogin");
    
    // save FB token and expiration date
    /*[[DataManager shared] saveFBToken:[FBService shared].facebook.accessToken
                              andDate:[FBService shared].facebook.expirationDate];*/
    
    
    // auth in Chat
    //[[FBService shared] logInChat];
    
    // get user's profile
    [[FBService shared] userProfileWithDelegate:self];
    
    [self.activityIndicator startAnimating];
    [self showLoginButton:NO];
}

- (void)fbDidNotLogin:(BOOL)cancelled{}
- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt{}

- (void)fbDidLogout{
    // Clear cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]){
        NSString* domainName = [cookie domain];
        NSRange domainRange = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0){
            [storage deleteCookie:cookie];
        }
    }
}

- (void)fbSessionInvalidated{}


#pragma mark -
#pragma mark FBServiceResultDelegate

-(void)completedWithFBResult:(FBServiceResult *)result{
    
    // get User profile result
    if(result.queryType == FBQueriesTypesUserProfile){
        // save FB user
        [User sharedInstance].currentFBUser = [result.body mutableCopy];
        [User sharedInstance].currentFBUserId = [[User sharedInstance].currentFBUser objectForKey:kId];
        
        // try to auth
        NSString *userLogin = [[NumberToLetterConverter instance] convertNumbersToLetters:[[User sharedInstance].currentFBUser objectForKey:kId]];
        NSString *passwordHash = [NSString stringWithFormat:@"%u", [[[User sharedInstance].currentFBUser objectForKey:kId] hash]];
        
        // Authenticate user
        [QBUsers logInWithUserLogin:userLogin password:passwordHash delegate:self];
    }
}


#pragma mark -
#pragma mark QB QBActionStatusDelegate

// QuickBlox API queries delegate
-(void)completedWithResult:(Result *)result{
    
    // QuickBlox Application authorization result
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        // Success result
		if(result.success){
            
            // FB auth
            [FBService shared].facebook.accessToken = [[[User sharedInstance] fbUserTokenAndDate] objectForKey:FBAccessTokenKey];
            [FBService shared].facebook.expirationDate = [[[User sharedInstance] fbUserTokenAndDate] objectForKey:FBExpirationDateKey];
            
            if (![[FBService shared].facebook isSessionValid]) {
                
                // show Login & Registrations buttons
                [self.activityIndicator stopAnimating];
                
                [self showLoginButton:YES];
            }else{
                // get user's profile
                [[FBService shared] userProfileWithDelegate:self];
                
                // auth in Chat
                [[FBService shared] logInChat];
                
                
                // restore FB cookies
                NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:FB_COOKIES];
                NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                for(NSHTTPCookie *cook in cookies){
                    if([cook.domain rangeOfString:@"facebook.com"].location != NSNotFound){
                        [cookiesStorage setCookie:cook];
                    }
                }
            }
            
            // Errors
        }else{
            NSString *message = [result.errors stringValue];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Errors", nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            //[alert release];
            
            [self.activityIndicator stopAnimating];
        }
        
        // QuickBlox User authenticate result
    }else if([result isKindOfClass:[QBUUserLogInResult class]]){
        // Success result
		if(result.success){
            QBUUserLogInResult *res = (QBUUserLogInResult *)result;
            
            // save current user
            [User sharedInstance].currentQBUser = res.user;
            
			// register as subscribers for receiving push notifications
            [QBMessages TRegisterSubscriptionWithDelegate:self];
            
            // Errors
		}else if(401 == result.status){
            
            // Register new user
            // Create QBUUser entity
            QBUUser *user = [[QBUUser alloc] init];
            NSString *userLogin = [[NumberToLetterConverter instance] convertNumbersToLetters:[[User sharedInstance].currentFBUser objectForKey:kId]];
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [[[User sharedInstance].currentFBUser objectForKey:kId] hash]];
            user.login = userLogin;
            user.password = passwordHash;
            user.facebookID = [[User sharedInstance].currentFBUser objectForKey:kId];
            user.tags = [NSArray arrayWithObject:@"Chattar"];
            
            // Create user
            [QBUsers signUp:user delegate:self];
            // Errors
		}else{
            NSString *message = [result.errors stringValue];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Errors", nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            
            [self.activityIndicator stopAnimating];
        }
        
        // Create user result
    }else if([result isKindOfClass:[QBUUserResult class]]){
		
        // Success result
		if(result.success){
            
            // auth again
            NSString *userLogin = [[NumberToLetterConverter instance] convertNumbersToLetters:[[User sharedInstance].currentFBUser objectForKey:kId]];
            NSString *passwordHash = [NSString stringWithFormat:@"%u", [[[User sharedInstance].currentFBUser objectForKey:kId] hash]];
            
            // authenticate user
            [QBUsers logInWithUserLogin:userLogin password:passwordHash delegate:self];
            
            // show Errors
        }else{
            NSString *message = [result.errors stringValue];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Errors", nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            
            [self.activityIndicator stopAnimating];
        }
        
    }else if([result isKindOfClass:[QBMRegisterSubscriptionTaskResult class]]){

        [self.activityIndicator stopAnimating];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        UsersListViewController *usersListViewController = [[UsersListViewController alloc]     initWithNibName:@"UsersListViewController" bundle:nil];
        [self.navigationController pushViewController:usersListViewController animated:YES];
        
        [[FBService shared].facebook setSessionDelegate:nil];
        
        // save FB cookies
        NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [cookiesStorage cookies];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:FB_COOKIES];
    }

}

@end
