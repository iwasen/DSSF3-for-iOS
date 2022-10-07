//
//  PrefViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrefView.h"
#import "Common.h"
#import "FileIO.h"

@interface PrefViewController : UIViewController <GraphViewDelegate>

@property (nonatomic) DbImpulseRec *pDbImpulseRec;
@property (nonatomic) DbAcParamRec *pDbAcParamRec;
@property (nonatomic) float fScale;
@property (nonatomic) float fAdjustSPL;

- (void)initialize;
- (void)redraw;

@end
