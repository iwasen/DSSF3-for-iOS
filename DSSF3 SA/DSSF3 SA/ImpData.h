//
//  ImpData.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/09.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImpData : NSObject

@property (nonatomic) int dataId;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *date;
@property (nonatomic) NSString *comment;
@property (nonatomic) BOOL calculated;

@end
