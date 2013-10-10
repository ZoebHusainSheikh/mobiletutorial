//
//  User.m
//  MobileTutorialApp
//
//  Created by MAC1 on 10/10/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "User.h"

@implementation User


+ (User*)sharedInstance {
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

@end
