//
//  BrightnessViewCell.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/04.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "BrightnessViewCell.h"
#import "Common.h"

@interface BrightnessViewCell ()

@property (nonatomic, weak) IBOutlet UISlider *outletBrightness;

@end


@implementation BrightnessViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

//	self.outletBrightness.value = g_oSetData.fBgBrightness;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onChangeBgBrightness:(id)sender
{
//	g_oSetData.fBgBrightness = self.outletBrightness.value;
//	self.backgroundColor = [Brightness getBackgroundColor:[UIColor whiteColor]];
}

@end
