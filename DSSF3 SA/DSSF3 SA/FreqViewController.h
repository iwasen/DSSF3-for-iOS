//
//  FreqViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FreqView.h"
#import "Common.h"
#import "FileIO.h"

@interface FreqViewController : UIViewController <GraphViewDelegate>

@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) float *pWaveLeft;
@property (nonatomic) float *pWaveRight;
@property (nonatomic) float fRate;

- (void)initialize;
- (void)redraw;

@end
