//
//  InformationViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/17.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileIO.h"

@interface InformationViewController : UIViewController

@property (nonatomic) BOOL bCalculated;
@property (nonatomic) DbFolderRec *dbFolderRec;
@property (nonatomic) DbImpulseRec *dbImpulseRec;
@property (nonatomic) DbAcParamRec *dbAcParamRec;
@property (nonatomic) int nWaveData;
@property (nonatomic) float fScale;

@end
