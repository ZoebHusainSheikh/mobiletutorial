//
//  FriendsListViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class VideoCallViewController;

@interface FriendsListViewController : FBFriendPickerViewController <FBFriendPickerDelegate, QBActionStatusDelegate, QBChatDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) QBVideoChat *videoChat;
@property (strong, nonatomic) VideoCallViewController *videoCallViewController;

@end
