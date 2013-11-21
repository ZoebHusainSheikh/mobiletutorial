//
//  UserProfileViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 11/13/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "UserProfileViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "User.h"

@interface UserProfileViewController ()

@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak ,nonatomic) IBOutlet FBProfilePictureView *profilePictureView;

@end

@implementation UserProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem.image = [UIImage imageNamed:@"friends"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.profilePictureView.profileID = [User sharedInstance].currentQBUser.facebookID;
    self.userName.text = [User sharedInstance].currentQBUser.fullName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
