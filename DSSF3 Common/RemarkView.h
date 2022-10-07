//
//  RemarkView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/31.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

struct REMARK_INFO {
	int nRemark;
	struct {
		UIColor *color;
		NSString *text;
		BOOL dash;
	} remarks[10];
};

@interface RemarkView : UIView

- (void)dispRemarks:(const REMARK_INFO *)pRemark :(int)nFontPoint :(UIView *)viewParent;

@end
