//
//  RecorderViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/05.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioEx.h"
#import "RecView.h"
#import "RecordListViewController.h"

@interface RecorderViewController : UIViewController <AudioRecorder, GraphViewDelegate, UITextFieldDelegate, RecordListDelegate, RecViewDelegete, AudioInputData>

@end
