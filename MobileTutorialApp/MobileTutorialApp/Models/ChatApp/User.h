//
//  User.h
//  MobileTutorialApp
//
//  Created by MAC1 on 10/10/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

// current User
@property (nonatomic, strong) NSMutableDictionary	*currentFBUser;
@property (nonatomic, strong) QBUUser				*currentQBUser;
@property (strong, nonatomic) QBUUser               *opponent;

+ (User *)sharedInstance;

@end
