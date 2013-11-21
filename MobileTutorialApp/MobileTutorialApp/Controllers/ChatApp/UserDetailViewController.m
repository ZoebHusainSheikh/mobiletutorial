//
//  UserDetailViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "UserDetailViewController.h"
#import "User.h"
#import "VideoCallViewController.h"

@interface UserDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lastRequestAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *websiteLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;

- (IBAction)back:(id)sender;
- (IBAction)callButtonPressed:(id)sender;

@end

@implementation UserDetailViewController

#pragma mark init method

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.loginLabel.text = self.selectedUser.login;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.lastRequestAtLabel.text = [dateFormatter stringFromDate:self.selectedUser.lastRequestAt ?
                               self.selectedUser.lastRequestAt : self.selectedUser.createdAt];
    
    self.fullNameLabel.text = self.selectedUser.fullName;
    self.phoneLabel.text = self.selectedUser.phone;
    self.emailLabel.text = self.selectedUser.email;
    self.websiteLabel.text = self.selectedUser.website;
    
    for(NSString *tag in self.selectedUser.tags){
        if([self.tagLabel.text length] == 0){
            self.tagLabel.text = tag;
        }else{
            self.tagLabel.text = [NSString stringWithFormat:@"%@, %@", self.tagLabel.text, tag];
        }
    }
    
    if ([self.selectedUser.fullName length] == 0)
    {
        self.fullNameLabel.text = @"empty";
        self.fullNameLabel.alpha = 0.3;
    }
    if ([self.selectedUser.phone length] == 0)
    {
        self.phoneLabel.text = @"empty";
        self.phoneLabel.alpha = 0.3;
    }
    if ([self.selectedUser.email length] == 0)
    {
        self.emailLabel.text = @"empty";
        self.emailLabel.alpha = 0.3;
    }
    if ([self.selectedUser.website length] == 0)
    {
        self.websiteLabel.text = @"empty";
        self.websiteLabel.alpha = 0.3;
    }
    if ([self.selectedUser.tags count] == 0)
    {
        self.tagLabel.text = @"empty";
        self.tagLabel.alpha = 0.3;
    }
}

#pragma mark IBAction methods

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)callButtonPressed:(id)sender {
    
    /*VideoCallViewController *videoCallViewController = [[VideoCallViewController alloc] initWithNibName:@"VideoCallViewController" bundle:nil];
    [User sharedInstance].opponent = self.selectedUser;
    videoCallViewController.videoChat = self.usersListViewController.videoChat;
    self.usersListViewController.videoCallViewController = videoCallViewController;
    [self.navigationController pushViewController:videoCallViewController animated:YES];*/
}


@end
