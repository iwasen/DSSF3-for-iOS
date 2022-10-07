//
//  MtfViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MtfView.h"
#import "Common.h"
#import "FileIO.h"

@interface MtfViewController : UIViewController <GraphViewDelegate>

@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) DbAcParamResult *pDbAcParamResult;
@property (nonatomic) float *pIRLeft;
@property (nonatomic) float *pIRRight;
@property (nonatomic) float fRate;
@property (nonatomic) int nData;

- (void)initialize;
- (void)redraw;

@end
