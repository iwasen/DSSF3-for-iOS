//
//  DrawView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/12.
//  Copyright c  2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>

extern void DrawString(NSString *string, CGFloat x, CGFloat y, NSDictionary *attrs);
extern void DrawRotateString(CGContextRef context, NSString *string, CGFloat x, CGFloat y, NSDictionary *attrs);
extern void DrawLine(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color);
extern void DrawPolyline(CGContextRef context, CGPoint *points, int count, UIColor *color);
extern void DrawPolygon(CGContextRef context, CGPoint *points, int count, UIColor *strokeColor, UIColor *fillColor);
extern void DrawRectangle(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color);
extern void DrawFillRect(CGContextRef context, CGFloat left, CGFloat top, CGFloat width, CGFloat height, UIColor *color);
extern void DrawFillRectRGB(CGContextRef context, CGFloat left, CGFloat top, CGFloat width, CGFloat height, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
extern void DrawFillPath(CGContextRef context, CGPoint *points, int count, UIColor *color);
extern void DrawLineSegments(CGContextRef context, CGPoint *segments, int count, UIColor *color);
extern void DrawFillEllipse(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color);
