//
//  MyTabBar.m
//  Test1
//
//  Created by 相沢伸一 on 2017/12/10.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "MyTabBar.h"

@implementation MyTabBar

- (UITraitCollection *)traitCollection
{
	UITraitCollection *curr = [super traitCollection];
	UITraitCollection *compact = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];

	return [UITraitCollection traitCollectionWithTraitsFromCollections:@[curr, compact]];
}

@end
