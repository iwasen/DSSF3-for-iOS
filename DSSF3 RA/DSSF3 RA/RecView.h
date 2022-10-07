//
//  RecView.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/06.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@protocol RecViewDelegete <NSObject>

- (void)getSelectArea:(float *)selectStart :(float *)selectEnd;
- (void)changeSelectStart:(float)selectStart;
- (void)changeSelectEnd:(float)selectEnd;

@end

@interface RecView : GraphView

- (void)initialize;
- (void)dispGraph:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData :(int)nLR :(float)fMaxData :(float)selectStart :(float)selectEnd;

@property (nonatomic, weak) IBOutlet id<RecViewDelegete> delegate2;

@end
