//
//  ImpView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImpDrawGraphDelegate

- (void)drawGraphData:(CGContextRef)context :(int)nChannel;

@optional

- (void)moveGraph:(id)sender :(float)move;
- (void)zoomGraph:(id)sender :(float)zoom;

@end

@interface ImpView : UIView

@property (nonatomic, weak) IBOutlet id<ImpDrawGraphDelegate> delegate;
@property (nonatomic) BOOL enabled;

- (void)initialize:(NSString *)pTitle :(int)nChannel;
- (void)drawData:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData;

@end
