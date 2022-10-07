//
//  IACCViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IACCView.h"
#import "Common.h"
#import "FileIO.h"
#import "CalcIACCViewController.h"

@interface IACCViewController : UIViewController <GraphViewDelegate, CalcIACCViewControllerDelegate>

@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) DbAcParamRec *pDbAcParamRec;
@property (nonatomic) float *pIRLeft;
@property (nonatomic) float *pIRRight;
@property (nonatomic) float fRate;
@property (nonatomic) HWAVEDATA hWaveData;

- (void)initialize;
- (void)redraw;

@end
