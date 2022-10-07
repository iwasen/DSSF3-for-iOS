//
//  RtaTabBarController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/16.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "RtaTabBarController_iPhone.h"
#import "MainViewController.h"
#import "Common.h"

@implementation RtaTabBarController_iPhone
{
    NSDictionary *waveFileInfo;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = self;

    self.selectedIndex = g_oSetData.nSelectedTab;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyLoadWaveFile:) name:@"LoadWaveFile" object:nil];
    [nc addObserver:self selector:@selector(notifyQueryWaveFile:) name:@"QueryWaveFile" object:nil];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)notifyLoadWaveFile:(NSNotification *)center
{
    waveFileInfo = center.userInfo;

    g_oSetData.nSelectedTab = 6;
    self.selectedIndex = g_oSetData.nSelectedTab;
}

- (void)notifyQueryWaveFile:(NSNotification *)center
{
    if (waveFileInfo != nil) {
        NSNotification *notification = [NSNotification notificationWithName:@"LoadWaveFile" object:self userInfo:waveFileInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        waveFileInfo = nil;
    }
}

- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
    if (g_oSetData.nSelectedTab != (int)self.selectedIndex) {
        g_oSetData.nSelectedTab = (int)self.selectedIndex;
        [self setMainTitle];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	[self setMainTitle];
}

- (void)setMainTitle
{
	MainViewController *mainViewController = (MainViewController *)self.parentViewController;
	[mainViewController setMainTitle:self.tabTitles[self.selectedIndex]];
}

- (void)initViews
{
    self.selectedIndex = g_oSetData.nSelectedTab;
    [self setMainTitle];
}

@end
