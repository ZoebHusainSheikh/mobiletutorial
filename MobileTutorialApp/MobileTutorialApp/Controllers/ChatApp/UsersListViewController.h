//
//  UsersListViewController.h
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersListViewController : UIViewController <QBActionStatusDelegate, UITextFieldDelegate,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) QBUUser *currentUser;

@end
