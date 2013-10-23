//
//  UsersListViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoCallViewController;

@interface UsersListViewController : UIViewController <QBActionStatusDelegate, QBChatDelegate, UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) QBVideoChat *videoChat;
@property (strong, nonatomic) VideoCallViewController *videoCallViewController;

@end
