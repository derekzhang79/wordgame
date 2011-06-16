//
//  wordsleuthAppDelegate.m
//  wordsleuth
//
//  Created by Brian D. Elliott on 4/14/11.
//  Copyright 2011 Sparkle Software. All rights reserved.
//

#import "wordsleuthAppDelegate.h"
#import "HighScoresController.h"
#import "Launch.h"
#import "iRate.h"
#import "Analytics.h"

NSString* const GameStateLoaded = @"GameStateLoaded";
NSString* const ApplicationBecameActive = @"ApplicationBecameActive";


@implementation wordsleuthAppDelegate

@synthesize window=_window;

@synthesize navigationController = _navigationController;

@synthesize playGameController;

@synthesize ratingDelegate;
@synthesize bragFacebook;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // load application in background
    [NSThread detachNewThreadSelector:@selector(loadApplication) toTarget:self withObject:nil];
    
    // display launch splash screens
    self.window.rootViewController = [[[Launch alloc] init] autorelease];    
    [self.window makeKeyAndVisible];
    
    // start time for launch screens; display app if load takes less time
    launchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(launchDisplayCompleted) userInfo:nil repeats:NO];

    return YES;
}

// all application initilization should take place here
- (void) loadApplication {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // turn on analytics:
    [Analytics startAnalytics];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [self loadGameState];

    [self configureAppRating]; // configure prompting for app store ratings.
    
    self.bragFacebook = [[BragFacebook alloc] init];
    
    [pool release];    
}

- (void) launchDisplayCompleted {
    launchDisplayCompleted = YES;
    [self loadGameView];
}

- (void) loadGameState {
    // first check if the user has already played today:
    playedToday = [self hasPlayedToday];
    hasGameState = YES;
    
    // BDE egregious testing hack:
    //playedToday = NO;
    
    // display game view, in case load took longer than launch timer
    // all calls to UIKit must be from main thread
    [self performSelectorOnMainThread:@selector(loadGameView) withObject:nil waitUntilDone:NO];
}

- (void) loadGameView {
    if (hasGameState && launchDisplayCompleted) {
        self.window.rootViewController = self.navigationController;
        
        if (playedToday) {
            // skip to high scores screen with timer
            NSLog(@"User already played today, going to high scores.");
            int lastPlayedNumGuesses = [self getLastPlayedNumGuesses];
            [HighScoresController goToHighScores:lastPlayedNumGuesses];            
            
        } else {
            NSLog(@"User has not played yet today, initializing game.");
            [self startGame];            
        }
    }
}

- (void)startGame {

    NSLog(@"wordsleuth:startGame");
    if (!self.playGameController) {
        // user has not played today:
        self.playGameController = [[PlayGameController alloc] initWithNibName:@"PlayGame" bundle:nil];
        [self.navigationController pushViewController:self.playGameController animated:TRUE];
    }
    
    [self.navigationController popToViewController:self.playGameController animated:TRUE];

}




- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    //NSLog(@"WSAD: applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */

    //NSLog(@"WSAD: applicationDidEnterBackground");

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */

    NSLog(@"WSAD: applicationWillEnterForeground");

    [Analytics logEvent:@"App becoming active again"];
    

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ApplicationBecameActive object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */

    //NSLog(@"WSAD: applicationWillTerminate");

}

- (void)dealloc
{
    [_window release];
    [_navigationController release];
    [playGameController release];
    [ratingDelegate release];
    [super dealloc];
}

- (NSDate *) lastPlayedDate {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults objectForKey:@"lastPlayed"];
}

- (BOOL)hasPlayedToday {
    
    NSDate *lastPlayed;
    lastPlayed = [self lastPlayedDate];

    NSLog(@"Game last played on: %@", lastPlayed);
    
    if (!lastPlayed) {
        // user has never played
        return FALSE;
    }
    
    // get current date/time
    NSDate *now = [NSDate date]; // returns the UTC date/time
    
    // test if the two are the same day using the truly odd
    // NSCalendar and NSDateComponent classes!  could they make
    // this any uglier?
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    unsigned uglyDateComponentOrBits = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *lastComponents = [cal components:uglyDateComponentOrBits fromDate:lastPlayed];
    NSDateComponents *nowComponents = [cal components:uglyDateComponentOrBits fromDate:now];
    
    NSInteger lastYear = [lastComponents year];
    NSInteger lastMonth = [lastComponents month];
    NSInteger lastDay = [lastComponents day];
    
    NSInteger nowYear = [nowComponents year];
    NSInteger nowMonth = [nowComponents month];
    NSInteger nowDay = [nowComponents day];
    
    if (lastYear != nowYear)
        return FALSE;
    if (lastMonth != nowMonth)
        return FALSE;
    return (lastDay == nowDay);
    
}

- (int)getLastPlayedNumGuesses {

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    
    // returns 0 if int not found.
    int lastPlayedNumGuesses = [standardUserDefaults integerForKey:@"lastPlayedNumGuesses"];
    return lastPlayedNumGuesses;
}

- (void)configureAppRating {
    // setup prompting for app store ratings.
    
    iRate *irate = [iRate sharedInstance];
    
    //configure iRate
	irate.appStoreID = 442117507;   // app id from iTunes connect
	irate.applicationName = @"Word du Jour";
    
    irate.disabled = FALSE;  // disable automatic prompting upon application launch.
    
    irate.daysUntilPrompt = 0.0001; // set it effectively to 0 days.  we're prompting by number of games
                                    // so this setting just effectively disables the time checking.
    
    irate.usesUntilPrompt = 0; // don't care how many times the app is launched.
    
    // do not prompt until 3 games played.  each game is manually flagged as an event:
    // prompt will appear once a game is completed AND the app is re-launched.
    irate.eventsUntilPrompt = 1; 
    
    irate.remindPeriod = 7; // reminder after 7 days if they choose not to rate.
    
    irate.debug = NO; // if YES, prompt is always shown. (above settings ignored)
    
    // simple delegate to display any errors communicating with the app store
    self.ratingDelegate = [[RatingDelegate alloc] init];
    [iRate sharedInstance].delegate = self.ratingDelegate;
    
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    /* stupid facebook sdk forces you to put this method in the application delegate */
    return [bragFacebook application:application handleOpenURL:url]; 

}

@end
