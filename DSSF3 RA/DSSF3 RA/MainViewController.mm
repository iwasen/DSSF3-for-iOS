//
//  MainViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/08.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "MainViewController.h"
#import "Common.h"
#import "RtaTabBarController.h"
#import "AudioEx.h"
#import "VersionViewController.h"
#import "UIViewController+MJPopupViewController.h"

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.translucent = NO;

    // for iOS14
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        appearance.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }

    [AudioInputEx setMonitor:self];
    [AudioOutputEx setMonitor:self];
}

- (void)audioInputStop
{
    [self.outletRtaView.outletInputIndicator clear];
}

- (void)audioInputData:(AudioData *)audioData
{
    [self.outletRtaView.outletInputIndicator inputAudioData:audioData];
}

- (void)audioOutputStop
{
    [self.outletRtaView.outletOutputIndicator clear];
}

- (void)audioOutputData:(AudioData *)audioData
{
    [self.outletRtaView.outletOutputIndicator inputAudioData:audioData];
}

- (void)setMainTitle:(NSString *)subTitle
{
	self.navigationItem.title = [NSString stringWithFormat:@"DSSF3 - %@", subTitle];
}

- (IBAction)onVersionButton:(id)sender
{
	VersionViewController *versionViewController = [[VersionViewController alloc] initWithNibName:@"VersionView" bundle:nil];
	versionViewController.parent = self;
	[self presentPopupViewController:versionViewController animationType:MJPopupViewAnimationFade enableBackground:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Settings"]) {
		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] init];
		barButton.title = NSLocalizedString(@"IDS_BACK", nil);
		self.navigationItem.backBarButtonItem = barButton;
	}
}

@end
