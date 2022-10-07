//
//  GraphView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GraphViewDelegate <NSObject>

- (void)drawGraphData:(CGContextRef)context :(id)sender;

@optional

- (void)moveGraph:(id)sender :(float)move;
- (void)zoomGraph:(id)sender :(float)zoom;

@end

@interface GraphView : UIView
{
	int _nWidth, _nHeight;
	int _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom;
	int _nScaleWidth, _nScaleHeight;
}

@property (nonatomic, weak) IBOutlet id<GraphViewDelegate> delegate;
@property (nonatomic) BOOL enabled;

@end
