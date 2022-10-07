//
//  AppDelegate.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "SetData.h"
#import "FileIO.h"
#import "MMDB.h"
#import "Global.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	setData = [[SetData alloc] init];
	g_oPcserve.Initialize();

	UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController.childViewControllers[0];
//	UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//	navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
	splitViewController.delegate = self;
	splitViewController.navigationItem.title = NSLocalizedString(@"IDS_DSSF3_TITLE", nil);
	splitViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"IDS_BACK", nil) style:UIBarButtonItemStylePlain
															target:nil
															action:nil];
	if (IS_PAD) {
		splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
	}

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
	CDbImpulse dbImpulse;
	DbImpulseRec dbImpulseRec;

	NSArray *comps = [url.path.lastPathComponent componentsSeparatedByString:@"_"];
	if ([(NSString *)comps[0] compare:@"impulse"] == 0) {
		if (dbImpulse.Open()) {
			dbImpulseRec.nFolderID = 0;
			dbImpulse.GetNewID(&dbImpulseRec.nImpulseID);
			dbImpulseRec.nSampling = ((NSString *)comps[2]).intValue;
			dbImpulseRec.nMeasTime = ((NSString *)comps[5]).intValue;
			dbImpulseRec.nMeasNum = ((NSString *)comps[6]).intValue;
			dbImpulseRec.nChannel = ((NSString *)comps[3]).intValue;
			dbImpulseRec.nBit = ((NSString *)comps[4]).intValue;
			dbImpulseRec.sTime = comps[1];
			dbImpulseRec.sTitle = [NSString stringWithFormat:@"data_%@_%@", [(NSString *)comps[1] substringToIndex:8], [(NSString *)comps[1] substringFromIndex:8]];
			dbImpulseRec.nUseFilter = 0;
			dbImpulseRec.nIFilterID = 0;
			dbImpulseRec.fTemperature = 0;
			dbImpulseRec.fHumidity = 0;
			dbImpulseRec.nMultiplier = 1;
			dbImpulseRec.bImpulseData = 0;
			dbImpulse.StoreRec(&dbImpulseRec);

			NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:url.path];
			NSData *data = [fileHandle readDataToEndOfFile];
			MMWaveWriteDB(dbImpulse, "WAVEDATA", (const char *)data.bytes, (int)data.length);

			_importedImpulseId = dbImpulseRec.nImpulseID;

			UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController.childViewControllers[0];
			UIViewController *navigationViewController = splitViewController.childViewControllers[0];
			MasterViewController *masterViewController = navigationViewController.childViewControllers[0];
			[masterViewController reloadFolderList:0 :dbImpulseRec.nImpulseID];
		}
	}

	return YES;
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
	if (IS_PHONE) {
		if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] folderId] == 0)) {
			// Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
			return YES;
		} else {
			return NO;
		}
	} else {
		return NO;
	}
}

/*
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
	return NO;
}
*/
@end
