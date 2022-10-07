//
//  PresetEditViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2020/04/24.
//  Copyright © 2020 TRC. All rights reserved.
//

#import "PresetEditViewController.h"
#import "Common.h"

@interface PresetEditViewController ()

@property (nonatomic, weak) IBOutlet CtTextField *outletPresetName;

@end

@implementation PresetEditViewController

- (void)viewWillAppear:(BOOL)animated
{
    self.outletPresetName.text = self.fileName;
}

- (IBAction)onDone:(id)sender
{
    [self.delegate changeFileName:self.outletPresetName.text: self.index];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
