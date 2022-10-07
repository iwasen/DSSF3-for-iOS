//
//  DrawView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/12.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "DrawView.h"

void DrawString(NSString *string, CGFloat x, CGFloat y, NSDictionary *attrs)
{
    [string drawAtPoint:CGPointMake(x, y) withAttributes:attrs];
}

void DrawRotateString(CGContextRef context, NSString *string, CGFloat x, CGFloat y, NSDictionary *attrs)
{
    CGContextSaveGState(context);
    CGAffineTransform transform = CGAffineTransformMakeRotation(-90.0 * M_PI / 180.0);
    CGContextConcatCTM(context, transform);
    DrawString(string, y, x, attrs);
    CGContextRestoreGState(context);
}

void DrawLine(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color)
{
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
    CGContextStrokePath(context);
}

void DrawPolyline(CGContextRef context, CGPoint *points, int count, UIColor *color)
{
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextBeginPath(context);
    CGContextAddLines(context, points, count);
    CGContextStrokePath(context);
/*
    static CGPoint points2[768 * 2];
//    CGPoint *points2 = new CGPoint[count * 2];
    CGPoint *p = points2;
    *p++ = points[0];
    int i;
    for (i = 1; i < count - 1; i++) {
        *p++ = points[i];
        *p++ = points[i];
    }
    *p++ = points[i];
    CGContextStrokeLineSegments(context, points2, p - points2);
//    delete [] points2;
*/
/*
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddLines(path, NULL, lines, count);
    UIBezierPath *path2 = [UIBezierPath bezierPathWithCGPath:path];
    [path2 stroke];
*/
}

void DrawPolygon(CGContextRef context, CGPoint *points, int count, UIColor *strokeColor, UIColor *fillColor)
{
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextBeginPath(context);
    CGContextAddLines(context, points, count);
    CGContextDrawPath(context, kCGPathFillStroke);
}

void DrawRectangle(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color)
{
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextStrokeRect(context, CGRectMake(x1, y1, x2 - x1, y2 - y1));
}

void DrawFillRect(CGContextRef context, CGFloat left, CGFloat top, CGFloat width, CGFloat height, UIColor *color)
{
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(left, top, width, height));
}

void DrawFillRectRGB(CGContextRef context, CGFloat left, CGFloat top, CGFloat width, CGFloat height, CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextFillRect(context, CGRectMake(left, top, width, height));
}

void DrawFillPath(CGContextRef context, CGPoint *points, int count, UIColor *color)
{
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextBeginPath(context);
    CGContextAddLines(context, points, count);
    CGContextFillPath(context);
}

void DrawLineSegments(CGContextRef context, CGPoint *segments, int count, UIColor *color)
{
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextStrokeLineSegments(context, segments, count);
}

void DrawFillEllipse(CGContextRef context, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2, UIColor *color)
{
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillEllipseInRect(context, CGRectMake(x1, y1, x2 - x1, y2 - y1));
}
