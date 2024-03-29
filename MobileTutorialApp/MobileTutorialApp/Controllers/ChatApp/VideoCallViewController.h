//
//  VideoCallViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoCallViewController : UIViewController

@property (strong, nonatomic) QBUUser *opponent;
@property (strong, nonatomic) QBVideoChat *videoChat;

- (void)callAccepted;
- (void)callDidStopByUser;
- (void)endVideoCall;
- (void)callRejected;

@end
