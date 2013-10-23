//
//  UserDetailViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UsersListViewController.h"
@interface UserDetailViewController : UIViewController

@property (strong, nonatomic) QBUUser *selectedUser;
@property (strong, nonatomic) UsersListViewController *usersListViewController;

@end
