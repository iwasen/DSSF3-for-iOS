//
//  RtaView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/19.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"
#import "IndicatorView.h"

@interface RtaView : UIView

@property (nonatomic, weak) IBOutlet IndicatorView *outletInputIndicator;
@property (nonatomic, weak) IBOutlet IndicatorView *outletOutputIndicator;

@end
