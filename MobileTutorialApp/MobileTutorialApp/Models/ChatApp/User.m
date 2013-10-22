//
//  User.m
//  MobileTutorialApp
//
//  Created by MAC1 on 10/10/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "User.h"
#import "Constants.h"

@implementation User


+ (User *)sharedInstance {
    static User* singleton = nil;
    
    @synchronized (self) {
        if (!singleton) {
            singleton = [[User alloc] init];
        }
    }
    
    return singleton;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.currentFBUser = nil;
        self.currentFBUserId = nil;
        self.currentQBUser = nil;
        /*historyConversation = [[NSMutableDictionary alloc] init];
         
         // logout
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutDone) name:kNotificationLogout object:nil];*/
    }
    return self;
}


#pragma mark -
#pragma mark FB access

- (void)saveFBToken:(NSString *)token andDate:(NSDate *)date{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:token forKey:FBAccessTokenKey];
    [defaults setObject:date forKey:FBExpirationDateKey];
	[defaults synchronize];
    
    self.accessToken = token;
}

- (void)clearFBAccess{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FBAccessTokenKey];
    [defaults removeObjectForKey:FBExpirationDateKey];
	[defaults synchronize];
    
    self.accessToken = nil;
    
    // reset user
    self.currentFBUser = nil;
    self.currentQBUser = nil;
    self.currentFBUserId = nil;
}

- (NSDictionary *)fbUserTokenAndDate
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:FBAccessTokenKey] && [defaults objectForKey:FBExpirationDateKey]){
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:[defaults objectForKey:FBAccessTokenKey] forKey:FBAccessTokenKey];
		[dict setObject:[defaults objectForKey:FBExpirationDateKey] forKey:FBExpirationDateKey];
        
		return dict;
    }
    
    return nil;
}
@end
