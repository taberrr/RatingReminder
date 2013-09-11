//
//  RatingReminder.m
//  RatingReminder
//
//  Created by taber on 9/11/13.
//  Copyright (c) 2013 Taber Buhl. All rights reserved.
//

#import "RatingReminder.h"

@interface RatingReminder()
@property (nonatomic, retain) UIAlertView *alertView;
@property (assign) NSUserDefaults *defaults;
@end

@implementation RatingReminder

static RatingReminder *_sharedRatingReminder = nil;

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (RatingReminder *)sharedReminder
{
  static dispatch_once_t _ratingReminderPredicate = 0;
  
  dispatch_once(&_ratingReminderPredicate, ^{
    _sharedRatingReminder = [[self alloc] init];
    _sharedRatingReminder.defaults = [NSUserDefaults standardUserDefaults];
    _sharedRatingReminder.daysThreshold = 3; // 3 = default
    _sharedRatingReminder.snoozeDaysThreshold = 2; // 2 = default
    _sharedRatingReminder.launchesThreshold = 10; // 10 = default
  });
  
  return _sharedRatingReminder;
}

- (void)remind
{
  // bail if the user is already being reminded
  if (self.alertView != nil)
    return;
  
  NSBundle *bundle = [NSBundle mainBundle];
  NSDictionary *info = [bundle infoDictionary];
  NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
  NSLog(@"APP NAME: %@", prodName);
  
  if (!_title)
    self.title = [NSString stringWithFormat:@"Love %@?", prodName];
  
  if (!_message || [_message isEqualToString:@""]) {
    NSString *message = [NSString stringWithFormat:@"Do you have a second to rate this version of %@? I'd really appreciate it!", prodName];
    self.message = NSLocalizedString(message, message);
  }
  
  if (!_cancelButtonTitle)
    self.cancelButtonTitle = NSLocalizedString(@"No, sorry", @"No, sorry");
  
  if (!_snoozeButtonTitle)
    self.snoozeButtonTitle = NSLocalizedString(@"Maybe later", @"Maybe later");
  
  if (!_rateButtonTitle)
    self.rateButtonTitle = NSLocalizedString(@"OK", @"OK");
  
  self.alertView = [[UIAlertView alloc] initWithTitle:_title message:_message delegate:self cancelButtonTitle:_rateButtonTitle otherButtonTitles:_snoozeButtonTitle, _cancelButtonTitle, nil];
  [_alertView show];
}

- (void)remindIfNeeded
{
  // if this is a new app version, start from scratch
  NSString *lastVer = [_defaults stringForKey:kRRLastVersionSeenKey];
  
  //NSLog(@"lastVer: %@, curVer: %@, actioned this ver? %u", lastVer, [self currentAppVersion], [self didActionCurrentVersion]);
  if ((!lastVer || ![[self currentAppVersion] isEqualToString:lastVer]) && ![self didActionCurrentVersion]) {
    
    //NSLog(@"new version!! resetting reminder states...");
    [_defaults setObject:[self currentAppVersion] forKey:kRRLastVersionSeenKey];
    [_defaults setInteger:[NSDate timeIntervalSinceReferenceDate] forKey:kRRLastLaunchKey];
    [_defaults removeObjectForKey:kRRLaunchCountKey];
    [_defaults removeObjectForKey:kRRLastVersionActionedKey];
    [_defaults removeObjectForKey:kRRLastSnoozeKey];
    [_defaults synchronize];
  }
  
  // bail if the days threshold hasn't been met
  NSUInteger curTime = [NSDate timeIntervalSinceReferenceDate];
  NSUInteger lastTime = [_defaults integerForKey:kRRLastLaunchKey];
  NSUInteger daysDiff = (NSUInteger)truncf((curTime - lastTime) / 86400);
  if (daysDiff < _daysThreshold) {
    //NSLog(@"not reminding because you've only used this version for (%u - %u) %u of %u days", curTime, lastTime, daysDiff, _daysThreshold);
    return;
  }
  
  // bail if the user has actioned this version
  if ([self didActionCurrentVersion]) {
    //NSLog(@"not reminding because you've already actioned version %@", [self currentAppVersion]);
    return;
  }
  
  // bail if the user has snoozed this version
  NSUInteger snoozeTime = [_defaults integerForKey:kRRLastSnoozeKey];
  NSUInteger snoozeDaysDiff = (NSUInteger)truncf((curTime - snoozeTime) / 86400);
  //snoozeDaysDiff = 3; // TODO: temp snooze days
  //NSLog(@"snooze days diff: %lu", (unsigned long)snoozeDaysDiff);
  if (snoozeDaysDiff < _snoozeDaysThreshold) {
    //NSLog(@"not reminding because you've only snoozed for %u of %u day(s)", snoozeDaysDiff, _snoozeDaysThreshold);
    return;
  }
  
  // lastly, bail if the launch threshold hasn't been met
  NSUInteger launches = [_defaults integerForKey:kRRLaunchCountKey];
  if (launches < _launchesThreshold) {
    //NSLog(@"not reminding because you've only launched the app %u of %u times", launches, _launchesThreshold);
    return;
  }
  
  [self remind];
}

#pragma mark - AlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex) {
    case RR_ALERT_BOT_BUTTON_INDEX:
      //DLog(@"tapped bottom btn");
      //DLog(@"rated version %@", [self currentAppVersion]);
      [_defaults removeObjectForKey:kRRLastSnoozeKey];
      [_defaults setObject:[self currentAppVersion] forKey:kRRLastVersionActionedKey];
      [_defaults synchronize];
      [self launchAppStore];
      break;
      
    case RR_ALERT_MID_BUTTON_INDEX:
      //DLog(@"tapped mid btn");
      //DLog(@"declined version %@", [self currentAppVersion]);
      [_defaults removeObjectForKey:kRRLastSnoozeKey];
      [_defaults setObject:[self currentAppVersion] forKey:kRRLastVersionActionedKey];
      [_defaults synchronize];
      break;
      
    case RR_ALERT_TOP_BUTTON_INDEX:
      //DLog(@"tapped top btn");
      //DLog(@"snoozing for %u day(s)", _snoozeDaysThreshold);
      [_defaults setInteger:[NSDate timeIntervalSinceReferenceDate] forKey:kRRLastSnoozeKey];
      [_defaults synchronize];
      break;
      
    default:
      break;
  }
  
  _alertView.delegate = nil;
  [_alertView removeFromSuperview];
  self.alertView = nil;
}

#pragma mark - App states

- (void)appLaunched
{
  [[NSNotificationCenter defaultCenter] addObserver:_sharedRatingReminder selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  
  if (_debug) {
    [self remind];
    return;
  }
  
  [self remindIfNeeded];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  if (_debug) {
    [self remind];
    return;
  }
  
  if (![self didActionCurrentVersion]) {
    NSInteger launchCount = [_defaults integerForKey:kRRLaunchCountKey];
    [_defaults setInteger:launchCount + 1 forKey:kRRLaunchCountKey];
    [_defaults synchronize];
  }
  
  [self remindIfNeeded];
}

#pragma mark - Helpers

- (BOOL)didActionCurrentVersion
{
  NSString *actionedVer = [_defaults stringForKey:kRRLastVersionActionedKey];
  return (actionedVer != nil && [actionedVer isEqualToString:[self currentAppVersion]]);
}

- (NSString *)currentAppVersion
{
  //return @"2.4";
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

- (void)launchAppStore
{
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"*** Note: the App Store isn't available in the iPhone Simulator unfortuantely. Close your eyes and imagine that the App Store just launched. ***");
  return;
#endif
  
  NSString *storeUrl = [[NSString alloc] initWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%lu", (unsigned long)_appId];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:storeUrl]];
}

@end
