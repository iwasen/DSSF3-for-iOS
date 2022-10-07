//
//  CtComboBox.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/01.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CtComboBoxList;

IB_DESIGNABLE

@interface CtComboBox : UIButton

@property (nonatomic) int selectedIndex;
@property (nonatomic) int selectedItemData;
@property (nonatomic, readonly) NSMutableArray *items;

- (int)addItem:(const NSString *)string :(int)itemData;
- (void)resetContent;

@end
