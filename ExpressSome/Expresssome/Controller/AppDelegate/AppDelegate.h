//
//  AppDelegate.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/14/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)requestUpdateDeviceToken;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)registerPushNotificationForApplication:(UIApplication *)application;
- (void)unregisterPushNotificationForApplication:(UIApplication *)application;

@end

