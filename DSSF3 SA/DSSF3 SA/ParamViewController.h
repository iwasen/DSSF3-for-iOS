//
//  ParamViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParamView.h"
#import "Common.h"
#import "FileIO.h"

@interface ParamViewController : UIViewController <GraphViewDelegate>

@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) DbAcParamRec *pDbAcParamRec;
@property (nonatomic) float fAdjustSPL;

- (void)initialize;
- (void)redraw;

@end
