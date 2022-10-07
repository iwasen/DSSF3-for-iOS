//
//  SettingsViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/04.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "SettingsViewController.h"

@implementation SettingsViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	switch (indexPath.section) {
	case 0:
		cell = [tableView dequeueReusableCellWithIdentifier:@"Brightness" forIndexPath:indexPath];
		break;

	default:
		break;
	}

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
	case 0:
		return @"Background Brightness";
	}
	return @"";
}

@end
