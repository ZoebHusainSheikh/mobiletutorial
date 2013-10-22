//
//  User.h
//  MobileTutorialApp
//
//  Created by MAC1 on 10/10/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

// FB access
@property (nonatomic, strong) NSString				*accessToken;
@property (nonatomic, strong) NSDate				*expirationDate;

// current User
@property (nonatomic, strong) NSMutableDictionary	*currentFBUser;
@property (nonatomic, strong) NSString				*currentFBUserId;
@property (nonatomic, strong) QBUUser				*currentQBUser;

+ (User *)sharedInstance;

#pragma mark -
#pragma mark FB

- (void) saveFBToken:(NSString *)token andDate:(NSDate *)date;
- (void)clearFBAccess;
- (NSDictionary *) fbUserTokenAndDate;

@end
