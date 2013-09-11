//
//  RatingReminder.h
//  RatingReminder
//
//  Created by taber on 9/11/13.
//  Copyright (c) 2013 Taber Buhl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RatingReminder : NSObject <UIAlertViewDelegate>

@property (nonatomic, assign) BOOL debug;
@property (nonatomic, assign) NSUInteger appId;
@property (nonatomic, assign) NSUInteger daysThreshold;
@property (nonatomic, assign) NSUInteger snoozeDaysThreshold;
@property (nonatomic, assign) NSUInteger launchesThreshold;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, copy) NSString *snoozeButtonTitle;
@property (nonatomic, copy) NSString *rateButtonTitle;

+ (RatingReminder *)sharedReminder;

- (void)appLaunched;

@end
