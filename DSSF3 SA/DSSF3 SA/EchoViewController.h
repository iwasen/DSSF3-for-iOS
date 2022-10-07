//
//  EchoViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImpulseView.h"
#import "EchoView.h"
#import "Common.h"
#import "FileIO.h"
#import "CalcEchoViewController.h"

@interface EchoViewController : UIViewController <GraphViewDelegate, CalcEchoViewControllerDelegate>

@property (nonatomic) HWAVEDATA hWaveData;
@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) DbAcParamRec *pDbAcParamRec;
@property (nonatomic) float *pIRLeft;
@property (nonatomic) float *pIRRight;
@property (nonatomic) float fRate;
@property (nonatomic) int nData;
@property (nonatomic) float fStartTime;
@property (nonatomic) float fDispTime;

- (void)initialize;
- (void)redraw;

@end
