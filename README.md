RatingReminder
==============

A simple library for reminding your users to rate your app.

## License ##

BSD 3-Clause, see the LICENSE file for the full license.

## Technical requirements ##

- Targeting iOS 5.0+ by default, may work on 4.0+ but haven't tested it
- This library uses automatic reference counting (ARC), but should support projects using both ARC and manual reference counting if added as a subproject (details below).

## Usage/Superfast setup ##

1. Drag RatingReminder.xcodeproj into your project
2. Click your project and then your build target. Expand the "Target Dependencies" row. Add "UniversalLib (RatingReminder)" as a dependency.
3. Expand the "Link Binary With Libraries" row and add the libRatingReminder.a library.
4. Add the following code to your project's AppDelegate:

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
        // ...
        
        RatingReminder *reminder = [RatingReminder sharedReminder];
        reminder.debug = YES; // debug mode causes the alert to appear every time the app is opened or focused
        reminder.appId = 12345678; // or whatever your AppId is
        [reminder appLaunched];
        
        // ...
    }
