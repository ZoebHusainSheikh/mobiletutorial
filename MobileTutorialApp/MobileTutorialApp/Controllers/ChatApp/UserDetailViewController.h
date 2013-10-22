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

@property (nonatomic, strong) QBUUser *selectedUser;
@property (nonatomic, strong) UsersListViewController *usersListViewController;

@end
