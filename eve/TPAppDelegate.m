//
//  TPAppDelegate.m
//  eve
//
//  Created by Teddy Moussignac on 4/3/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import "TPAppDelegate.h"
#import "EVEUtils.h"
#import "EVEMapViewController.h"
#import "EVETableViewController.h"
#import "EVEUserViewController.h"

@interface TPAppDelegate()
@property (nonatomic, retain) EVETableViewController *List;
@property (nonatomic, retain) UIViewController *Map;
@property (nonatomic, retain) UIViewController *User;
@property (nonatomic, retain) UIViewController *Settings;
@property (nonatomic, retain) UIViewController *Search;

@property (nonatomic, retain) UINavigationController *ListContainer;
@property (nonatomic, retain) UINavigationController *MapContainer;
@property (nonatomic, retain) UINavigationController *UserContainer;

@property (nonatomic, retain) UITabBarController *TabBar;
@property (nonatomic, retain) EVEUtils *Utils;
@end

@implementation TPAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.Utils = [[EVEUtils alloc] init];
    
    self.List = [[EVETableViewController alloc] init];
    self.Map = [[EVEMapViewController alloc] init];
    self.User = [[EVEUserViewController alloc] init];
    
    self.ListContainer = [[UINavigationController alloc] initWithRootViewController:self.List];
    self.MapContainer = [[UINavigationController alloc] initWithRootViewController:self.Map];
    self.UserContainer = [[UINavigationController alloc] initWithRootViewController:self.User];
    
    // config
    self.List.title = [[self.Utils.config valueForKey:@"ListConfig"] valueForKey:@"title"];
    UIImage *listIcon = [UIImage imageNamed:@"854-list-selected"];
    self.List.tabBarItem.image = listIcon;
    self.List.tabBarItem.selectedImage = listIcon;
    [self.ListContainer.navigationBar setTranslucent:YES];
    self.ListContainer.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.ListContainer.navigationBar setBarTintColor:[self.Utils.theme valueForKey:@"themeColor"]];
    self.ListContainer.navigationBar.tintColor = [self.Utils.theme valueForKey:@"menuFontColor"];
    
    self.Map.title = [[self.Utils.config valueForKey:@"MapConfig"] valueForKey:@"title"];
    UIImage *geoIcon = [UIImage imageNamed:@"geo"];
    self.Map.tabBarItem.image = geoIcon;
    self.Map.tabBarItem.selectedImage = geoIcon;
    self.MapContainer.navigationBar.barStyle = self.ListContainer.navigationBar.barStyle;
    self.MapContainer.navigationBar.barTintColor = self.ListContainer.navigationBar.barTintColor;
    self.MapContainer.navigationBar.tintColor = self.ListContainer.navigationBar.tintColor;
    
    self.User.title = [[self.Utils.config valueForKey:@"UserConfig"] valueForKey:@"title"];
    UIImage *userIcon = [UIImage imageNamed:@"Contact"];
    self.User.tabBarItem.image = userIcon;
    self.User.tabBarItem.selectedImage = userIcon;
    self.UserContainer.navigationBar.barStyle = self.ListContainer.navigationBar.barStyle;
    self.UserContainer.navigationBar.barTintColor = self.ListContainer.navigationBar.barTintColor;
    self.UserContainer.navigationBar.tintColor = self.ListContainer.navigationBar.tintColor;
    
    
    // tabBar
    self.TabBar = [[UITabBarController alloc] init];
    self.TabBar.tabBar.tintColor = [UIColor colorWithRed:0.0/255.0 green:159.0/255.0 blue:195.0/255.0 alpha:1];
    self.TabBar.viewControllers = @[ self.ListContainer, self.MapContainer, self.UserContainer ];
    
    // window
    [self.window setRootViewController:self.TabBar];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"eve" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"eve.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
