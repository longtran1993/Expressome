//
//  AppDelegate.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/14/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "AppDelegate.h"
#import "EConstant.h"
#import "AFNetworking.h"
#import "ELoginViewController.h"
#import "UIImageView+WebCache.h"
#import "ECreateGroupViewController.h"
#import "ECommon.h"
#import "IQKeyboardManager.h"
#import "ESearchGroupViewController.h"
#import "EInviteGroupViewController.h"
#import "EGroupChatViewController.h"
#import "CoreData+MagicalRecord.h"
#import "EMessage.h"
#import "ENavigationController.h"
#import "EForgotPasswordViewController.h"
#import "EResetPasswordViewController.h"
#import "EFeedBackViewController.h"
#import "CrashReport.h"
#import "EContestPageViewController.h"
#import "EContestVoteViewController.h"
#import "TestFairy.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Init TestFairy
    //[TestFairy begin:@"874c32d03f9abd09657acc0c4d3557fb29d00ec9"];
    
    // Start network monitoring
    [[QNetHelper getInstance] startMonitoring];
    
    // Initialize app data
    if (![[[EUserData getInstance] objectForKey:DID_INIT_APP_UD_KEY] boolValue]) {
        //[[QNotificationHelper getInstance] setBadgeNumber:0];
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:YES] forKey:DID_INIT_APP_UD_KEY];
        [self initApp];
    }
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Expressome.sqlite"];
    
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[ESearchGroupViewController class]];
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[EInviteGroupViewController class]];
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[EGroupChatViewController class]];
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[EForgotPasswordViewController class]];
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[EResetPasswordViewController class]];
    [[IQKeyboardManager sharedManager] disableToolbarInViewControllerClass:[EFeedBackViewController class]];
    
    [self setApplicationBadgeNumber: 0];
    
    
    NSString *bundledPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CustomPathImages"];
    [[SDImageCache sharedImageCache] addReadOnlyCachePath:bundledPath];
        
    // Set tint color for UITabBar
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:91.0f/255.0f green:59.0f/255.0f blue:107.0f/255.0f alpha:1.0f]];
    
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    //[[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    // Init main window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Init QUIHelper with main window
    [[QUIHelper getInstance] initWithMainWindow:self.window];
    
    // Extract the notification data
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (!IS_NOT_NULL(notificationPayload)) {
        
        NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
        if (username && username.length > 0) {
            NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
            if (groupInfo != nil) {
                ETabBarController *tabBar = (ETabBarController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
                tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
                self.window.rootViewController = tabBar;
            } else {
                ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
                ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
                [navigationVC setViewControllers:@[createGroupVC]];
                self.window.rootViewController = navigationVC;
            }
        } else {
            ENavigationController *navController = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
            ELoginViewController *loginVC = (ELoginViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"loginVC"];
            [navController setViewControllers:@[loginVC]];
            self.window.rootViewController = navController;
        }
        
        [self.window makeKeyAndVisible];
    } else {
        // Handle notifications
        [self processNotifications: notificationPayload];
    }
    
    
    
//#ifdef CRASH_REPORT_ENABLE
    // Setup crash reporting
    [[CrashReport getInstance] install];
    [[CrashReport getInstance] sendLogsIfPresent];
//#endif
    
    //    // Handle notifications
    //    if (launchOptions != nil) {
    //        // Launched from push notification
    //        NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    //        [self processNotifications:notification];
    //    }
    
    [Fabric with:@[[Crashlytics class]]];
    
    return YES;
}

- (void)initApp
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Images"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
            DLog_Error(@"Create directory error: %@", error);
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kApplication_did_enter_background object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self setApplicationBadgeNumber: 0];
    [[NSUserDefaults standardUserDefaults] setObject: @NO forKey: kHandlePushNotification];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.window endEditing:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSNumber *num = [df objectForKey: kHandlePushNotification];
    if (IS_NOT_NULL(num)) {
        
        [df setObject: @YES forKey: kHandlePushNotification];
        [df synchronize];
    }
    
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self setApplicationBadgeNumber: 0];
    
    NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
    if (IS_NOT_NULL(username)) {
        [self registerPushNotification];
    } else {
        //[self unregisterPushNotificationForApplication: [UIApplication sharedApplication]];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    //    [self saveContext];
    
    // Uninstall crash reporting
    [[CrashReport getInstance] uninstall];
    
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "Thai-Nguyen.Expresssome" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Expresssome" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Expresssome.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Send request

- (void)requestUpdateDeviceToken:(NSString *)deviceToken
{
    dispatch_queue_t apiRequestQueue = dispatch_queue_create("Update Device Token Request Queue",NULL);
    dispatch_async(apiRequestQueue, ^{
        
        NSNumber *deviceId = [[EUserData getInstance] objectForKey:DEVICE_ID_UD_KEY];
        
        if (!IS_NOT_NULL(deviceToken) || !IS_NOT_NULL(deviceId)) {
            return;
        }
        
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
        
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIUpdateDeviceTokenPath];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setValue:deviceToken forKey:@"machineCode"];
        [params setValue:deviceId forKey:@"id"];
        
        [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *status = [responseObject valueForKey:kAPIResponseStatus];
            if ([status isEqualToString:kAPIResponseStatusSuccess]) {
                [[EUserData getInstance] setObject: deviceToken forKey:DEVICE_TOKEN_UD_KEY];
                [[EUserData getInstance] setObject:[NSNumber numberWithBool:YES] forKey:DID_GET_DEVICE_TOKEN_UD_KEY];
            }
            else {
                if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                    NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                    if(codeStatus == kAPI403ErrorCode) {
                        [[QUIHelper getInstance] showAlertLogoutMessage];
                    }
                    else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                        [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                    }
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            int x = 0;
        }];
    });
}

#pragma mark - PUSH NOTIFICATION

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *_token = nil;
    _token = [deviceToken description];
    _token = [_token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    _token = [_token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [self requestUpdateDeviceToken: _token];
    
    DLog_Low(@"Device token: %@", [[EUserData getInstance] objectForKey:DEVICE_TOKEN_UD_KEY]);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    DLog_Error(@"Failed to get token, error: %@", error);
}



-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    int count = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSNumber *badgeCount = [df objectForKey: kApp_Badge_Count];
    if (!IS_NOT_NULL(badgeCount)) {
        badgeCount = @(1);
        
    } else {
        badgeCount = [NSNumber numberWithInt: badgeCount.integerValue + 1];
    }
    
    [self setApplicationBadgeNumber: badgeCount.integerValue];
    [df setObject: badgeCount forKey: kApp_Badge_Count];
    [df synchronize];
    
    //[self increaseApplicationBadgeNumberBy: 1];
    
    // Play notification sound
    [[QNotificationHelper getInstance] playNotificationSound];;
    
    // Check group info first
    NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
    if (groupInfo == nil) return;
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive || [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        
        // Handle notifications
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        NSNumber *num = [df objectForKey: kHandlePushNotification];
        if (IS_NOT_NULL(num) && [num boolValue]) {
            // Handle notifications
             [self processNotifications:userInfo];
        }
        
        
    } else {
        // If app is active
        
        [self setApplicationBadgeNumber: 0];
        
        if([EJSONHelper valueFromData:[userInfo objectForKey:@"type"]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@_notification", [userInfo objectForKey:@"type"]] object:nil userInfo:userInfo];
        }
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSLog(@"url recieved: %@", url);
    NSLog(@"query string: %@", [url query]);
    NSLog(@"host: %@", [url host]);
    NSLog(@"url path: %@", [url path]);
    NSDictionary *dict = [self parseQueryString:[url query]];
    NSLog(@"query dict: %@", dict);
    
    NSString *token = [dict objectForKey:@"token"];
    if(token) {
        [self presentResetPasswordWithToken:token];
    }
    
    return TRUE;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)presentResetPasswordWithToken:(NSString *)token {
    // Get instance of login controller
    ELoginViewController *loginVC = (ELoginViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"loginVC"];
    
    // Get instance of reset password controller
    EResetPasswordViewController *resetPasswordVC = (EResetPasswordViewController *) [[QUIHelper getInstance] getViewControllerWithIdentifier:@"resetPasswordVC"];
    resetPasswordVC.token = token;
    
    // Get instance of navigation controller
    ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
    [navigationVC setViewControllers:@[loginVC, resetPasswordVC]];
    self.window.rootViewController = navigationVC;
}

- (void)processNotifications:(NSDictionary *)notification {
    NSLog(@"Notification XXX %@", notification);
    //    [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"%@", notification] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    //    return;
    
    
    NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];
    if (username && username.length > 0) {
        NSDictionary *groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
        if (groupInfo != nil) {
            ETabBarController *tabBar = (ETabBarController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"tabbar"];
            tabBar.selectedViewController = [tabBar.viewControllers objectAtIndex:0];
            self.window.rootViewController = tabBar;
        } else {
            ECreateGroupViewController *createGroupVC = (ECreateGroupViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"createGroupVC"];
            ENavigationController *navigationVC = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
            [navigationVC setViewControllers:@[createGroupVC]];
            self.window.rootViewController = navigationVC;
        }
    } else {
        ENavigationController *navController = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
        ELoginViewController *loginVC = (ELoginViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"loginVC"];
        [navController setViewControllers:@[loginVC]];
        self.window.rootViewController = navController;
    }
    
    // Check condition
    if([self.window.rootViewController isKindOfClass:[ETabBarController class]]) {
        if([EJSONHelper valueFromData:[notification objectForKey:@"type"]]) {
            
            // Get tabbar instance
            ETabBarController *tabBar = (ETabBarController *) self.window.rootViewController;
            UINavigationController *navController = (UINavigationController*)tabBar.selectedViewController;
            
            if([[notification objectForKey:@"type"] isEqualToString:kInviteGroupJoinContestMsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
                    contestPageVC.contestInfo = [notification objectForKey:@"data"];
                    contestPageVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestPageVC animated:YES];
                }
                
            }
            
            else if ([[notification objectForKey:@"type"] isEqualToString:kMessageGroupChatMsgType]) {
                NSArray *topViewControllers = tabBar.viewControllers;
                id chatGroupViewController = topViewControllers[1];
                if (![chatGroupViewController isKindOfClass:[EGroupChatViewController class]]) {
                    [tabBar setSelectedIndex:1];
                }
            }
            
            else if([[notification objectForKey:@"type"] isEqualToString:kStartContestRound1MsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
                    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithDictionary: [notification objectForKey:@"data"]];
                    [infoDict setObject: @1 forKey: @"round"];
                    contestVoteVC.contestInfo = infoDict;
                    contestVoteVC.openFromPush = YES;
                    contestVoteVC.contestType = kOnGoingContestType;
                    contestVoteVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestVoteVC animated:YES];
                }
            } else if([[notification objectForKey:@"type"] isEqualToString:kStartContestRound2MsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
                    
                    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithDictionary: [notification objectForKey:@"data"]];
                    [infoDict setObject: @2 forKey: @"round"];
                    contestVoteVC.contestInfo = infoDict;
                    contestVoteVC.openFromPush = YES;
                    contestVoteVC.contestType = kOnGoingContestType;
                    contestVoteVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestVoteVC animated:YES];
                }
                
            }
            else if([[notification objectForKey:@"type"] isEqualToString:kFinishContestMsgType] || [[notification objectForKey:@"type"] isEqualToString: kUserWinnerContestMsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
                    contestVoteVC.contestInfo = [notification objectForKey:@"data"];
                    contestVoteVC.contestType = kResultContestType;
                    contestVoteVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestVoteVC animated:YES];
                }
            }
            else if([[notification objectForKey:@"type"] isEqualToString:kJoinContestMsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
                    
                    //joinedStatus = 1;
                    
                    NSInteger userID = [[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue];
                    NSNumber *num = [[notification objectForKey: @"data"] objectForKey: @"contestOwner"];
                    if (!IS_NOT_NULL(num)) {
                        num = @(-1);
                    }
                    
                    if (num.integerValue == userID) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [notification objectForKey:@"data"]];
                        [dict setObject: @YES forKey: @"joinedStatus"];
                        contestPageVC.contestInfo = dict;
                    } else {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [notification objectForKey:@"data"]];
                        [dict setObject: @NO forKey: @"joinedStatus"];
                        contestPageVC.contestInfo = dict;
                    }
                    
                    contestPageVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestPageVC animated:YES];
                }//
            }
            else if([[notification objectForKey:@"type"] isEqualToString:kUserVotePhotoMsgType] || [[notification objectForKey:@"type"] isEqualToString:kUserVoteImageMsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    
                    EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
                    contestVoteVC.contestInfo = [notification objectForKey:@"data"];
                    contestVoteVC.contestType = kOnGoingContestType;
                    contestVoteVC.hidesBottomBarWhenPushed = YES;
                    contestVoteVC.openFromPush = YES;
                    [navController pushViewController: contestVoteVC animated:YES];
                    
                    //                    EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
                    //                    contestPageVC.contestInfo = [notification objectForKey:@"data"];
                    //                    contestPageVC.hidesBottomBarWhenPushed = YES;
                    //                    [navController pushViewController:contestPageVC animated:YES];
                }
            }
            else if([[notification objectForKey:@"type"] isEqualToString:kUserWinContestMsgType]) {
                if([EJSONHelper valueFromData:[notification objectForKey:@"data"]]) {
                    EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
                    contestPageVC.contestInfo = [notification objectForKey:@"data"];
                    contestPageVC.hidesBottomBarWhenPushed = YES;
                    [navController pushViewController:contestPageVC animated:YES];
                }
            }
        }
    }
    
    [self.window makeKeyAndVisible];
}

- (void)showLogin {
    ENavigationController *navController = (ENavigationController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"ENavigationControllerID"];
    ELoginViewController *loginVC = (ELoginViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"loginVC"];
    [navController setViewControllers:@[loginVC]];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
}


#ifdef __IPHONE_8_0

- (BOOL)checkNotificationType:(UIUserNotificationType)type
{
    UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return (currentSettings.types & type);
}

#endif

- (void)setApplicationBadgeNumber:(NSInteger)badgeNumber
{
    //return;
    /////////////////
    if (!badgeNumber) {
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        [df removeObjectForKey: kApp_Badge_Count];
        [df synchronize];
    }
    
    UIApplication *application = [UIApplication sharedApplication];
#ifdef __IPHONE_8_0
    // compile with Xcode 6 or higher (iOS SDK >= 8.0)
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        application.applicationIconBadgeNumber = badgeNumber;
    } else {
        if ([self checkNotificationType:UIUserNotificationTypeBadge]) {
            NSLog(@"badge number changed to %ld", badgeNumber);
            application.applicationIconBadgeNumber = badgeNumber;
        } else {
            NSLog(@"access denied for UIUserNotificationTypeBadge");
        }
    }
#else
    // compile with Xcode 5 (iOS SDK < 8.0)
    application.applicationIconBadgeNumber = badgeNumber;
#endif
}

- (void)resetApplicationBadgeNumberForApplication:(UIApplication *)application {
#ifdef __IPHONE_8_0
    // compile with Xcode 6 or higher (iOS SDK >= 8.0)
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        application.applicationIconBadgeNumber = 0;
    } else {
        if ([self checkNotificationType:UIUserNotificationTypeBadge]) {
            NSLog(@"badge number changed to %ld", 0);
            application.applicationIconBadgeNumber = 0;
        } else {
            NSLog(@"access denied for UIUserNotificationTypeBadge");
        }
    }
#else
    // compile with Xcode 5 (iOS SDK < 8.0)
    application.applicationIconBadgeNumber = 0;
#endif

}

- (void)registerPushNotification {
    // Register push notification
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert| UIRemoteNotificationTypeBadge)];
    }
    else{
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

- (void)registerPushNotificationForApplication:(UIApplication *)application {
    // Register for Push Notitications
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIRemoteNotificationType remoteNotificationTypes = (UIRemoteNotificationTypeAlert |
                                                        UIRemoteNotificationTypeBadge |
                                                        UIRemoteNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes:remoteNotificationTypes];
    }
}

- (void)unregisterPushNotificationForApplication:(UIApplication *)application {
    [application unregisterForRemoteNotifications];
}

@end
