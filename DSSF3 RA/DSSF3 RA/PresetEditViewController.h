//
//  PresetEditViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2020/04/24.
//  Copyright © 2020 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PresetEditViewControllerDelegate

- (void)changeFileName:(NSString *)fileName :(NSInteger)index;

@end

@interface PresetEditViewController : UIViewController

@property (nonatomic, weak) id<PresetEditViewControllerDelegate> delegate;
@property (nonatomic, weak) NSString *fileName;
@property (nonatomic) NSInteger index;

@end

NS_ASSUME_NONNULL_END
