RatingReminder
==============

A simple library for reminding your users to rate your app.

Usage Example
=============

Drag the .xcodeproj into your project, add the UniversalLib as a dependency and link the libRatingReminder.a library, then add the following to your AppDelegate.m file:

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        RatingReminder *reminder = [RatingReminder sharedReminder];
        reminder.debug = YES;
        reminder.appId = 12345678; // or whatever your AppId is
        [reminder appLaunched];
        
        ...
    }
