//
//  SignUpViewController.h
//  MobileTutorialApp
//
//  Created by MAC1 on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Facebook.h"
#import "FBServiceResultDelegate.h"

@interface SignUpViewController : UIViewController <QBActionStatusDelegate, FBServiceResultDelegate, FBSessionDelegate> {
    
}

@end
