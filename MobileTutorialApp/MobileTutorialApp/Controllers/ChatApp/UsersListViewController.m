//
//  UsersListViewController.m
//  MobileTutorialApp
//
//  Created by Systango on 10/11/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "UsersListViewController.h"
#import "FBService.h"
#import "User.h"
#import "UserCell.h"
#import "UserDetailViewController.h"

@interface UsersListViewController ()

@property (strong, nonatomic) NSMutableArray *searchUsers;
@property (strong, nonatomic) NSArray *users;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;

@end

@implementation UsersListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self retrieveUsers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Retrieve QuickBlox Users
- (void) retrieveUsers{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // retrieve 100 users
    PagedRequest* request = [[PagedRequest alloc] init];
    request.perPage = 100;
	[QBUsers usersWithPagedRequest:request delegate:self];
}

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result
{
    // Retrieve Users result
    if([result isKindOfClass:[QBUUserPagedResult class]])
    {
        // Success result
        if (result.success)
        {
            // update table
            QBUUserPagedResult *usersSearchRes = (QBUUserPagedResult *)result;
            self.users = usersSearchRes.users;
            self.searchUsers = [self.users mutableCopy];
            [self.usersTable reloadData];
            // Errors
        }else{
            NSLog(@"Errors=%@", result.errors);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    }else if([result isKindOfClass:[QBUUserLogOutResult class]]){
        
		QBUUserLogOutResult *res = (QBUUserLogOutResult *)result;
        
		if(res.success){
		    NSLog(@"LogOut successful.");
            self.currentUser = nil;
            [User sharedInstance].currentQBUser = nil;
            [self.navigationController popToRootViewControllerAnimated:YES];
		}else{
            NSLog(@"errors=%@", result.errors);
		}
	}

}


#pragma mark -
#pragma mark TableViewDataSource & TableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*[self.searchBar resignFirstResponder];
    
    // show user details
    detailsController.choosedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    [self presentModalViewController:detailsController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];*/
    
    // show user details
    UserDetailViewController *userDetailViewController = [[UserDetailViewController alloc] initWithNibName:@"UserDetailViewController" bundle:nil];
    userDetailViewController.selectedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    [self.navigationController pushViewController:userDetailViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchUsers count];
}

// Making table view using custom cells
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";

	UserCell *cell = (UserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) {
		NSArray *nibObjects;
         nibObjects = [[NSBundle mainBundle] loadNibNamed:@"UserCell"
													   owner:self
													 options:nil];
		cell = [nibObjects objectAtIndex:0];
	}

    QBUUser *obtainedUser = [self.searchUsers objectAtIndex:[indexPath row]];
    
    if(obtainedUser.login != nil) {
        cell.userName.text = obtainedUser.login;
    }
    else{
        cell.userName.text = obtainedUser.email;
    }
    
    return cell;
}
- (IBAction)logoutMe:(id)sender {
    // logout
    /*[[User sharedInstance] clearFBAccess];
    [[FBService shared].facebook logout];
    [self.navigationController popViewControllerAnimated:YES];*/
    
    // logout user
    if ([[QBChat instance]isLoggedIn]) {
        [[QBChat instance] logout];
    }
    [QBUsers logOutWithDelegate:self];
}

@end
