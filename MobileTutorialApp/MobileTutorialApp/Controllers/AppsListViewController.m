//
//  AppsListViewController.m
//  MobileTutorialApp
//
//  Created by Systango.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "AppsListViewController.h"
#import "LoginViewController.h"

#define kNumberOfAppsInTutorial 1;

@interface AppsListViewController ()

@property (nonatomic, strong) IBOutlet UITableViewCell *chatCell;

@end

@implementation AppsListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Mobile Tutorial";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return kNumberOfAppsInTutorial;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return self.chatCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Create the LoginViewController.

    [self.navigationController pushViewController:[[LoginViewController sharedInstance] initWithNibName:@"LoginViewController" bundle:nil] animated:YES];
}

@end

