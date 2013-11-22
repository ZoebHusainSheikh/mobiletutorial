//
//  LoginViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class UsersListViewController;

@interface LoginViewController : UIViewController <QBChatDelegate, QBActionStatusDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UITabBarController *tabBarController;

+ (LoginViewController *)sharedInstance;
- (void)qbChatRelogin;

@end
