//
//  UsersListViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoChatDelegate <NSObject>

- (void)callAccepted;
- (void)callRejected;
- (void)callDidStopByUser;
- (void)callDidStartWithUser;
@end

@interface UsersListViewController : UIViewController <QBActionStatusDelegate, QBChatDelegate, UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) QBUUser *currentUser;
@property (nonatomic, weak) QBVideoChat *videoChat;
@property (nonatomic, strong) id<VideoChatDelegate> delegate;

@end
