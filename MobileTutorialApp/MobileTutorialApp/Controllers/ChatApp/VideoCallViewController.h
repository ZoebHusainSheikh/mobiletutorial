//
//  VideoCallViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UsersListViewController.h"

@interface VideoCallViewController : UIViewController  <VideoChatDelegate>

@property (nonatomic, strong) QBUUser *receiver;
@property (nonatomic, strong) UsersListViewController *usersListViewController;
@end
