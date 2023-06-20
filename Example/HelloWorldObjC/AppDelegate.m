//
//  AppDelegate.m
//  HelloWorldObjC
//
//  Created by Mladjan Antic on 19.6.23..
//

#import "AppDelegate.h"
@import Aptabase;


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
    
    
    // Using cloud based APP key
    [[Aptabase shared] initializeWithAppKey:@"A-DEV-0000000000"];

    // Using self hosted APP key
//    [[Aptabase shared] initializeWithAppKey:@"A-SH-0000000000" parameters:@{@"host":@"https://yourdomain.com"}];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
