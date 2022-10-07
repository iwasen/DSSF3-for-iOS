//
//  KeyboardView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/18.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface KeyboardView : UIControl

- (void)setMarker:(int)nOctave :(int)nKey;

@property (nonatomic) int touchKey;
@property (nonatomic) int touchOctave;

@end
