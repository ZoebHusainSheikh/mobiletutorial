//
//  VideoCallViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoCallViewController : UIViewController  <QBChatDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) QBUUser *receiver;
@end
