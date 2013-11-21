//
//  Common.m
//  MobileTutorialApp
//
//  Created by Systango on 10/8/13.
//  Copyright (c) 2013 Systango. All rights reserved.
//

#import "Common.h"

@implementation Common

+ (void)showAlertWithTitle:(NSString *)title description:(NSString *)description{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
														message:description
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
    [alertView show];
    alertView = nil;
    
}

+ (void)showNetworkErrorAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection"
                                                    message:@"Please check your internet/Wifi connection."
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
