//
//  SubViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/08.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SubViewController.h"
#import "AppDelegate.h"

@implementation SubViewController

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// キーボード表示・非表示時のイベント登録
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
	[nc addObserver:self selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShown:(NSNotification *)notification {
	// キーボードの表示完了時の場所と大きさを取得。
	CGRect keyboardFrameEnd = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGFloat screenHeight = screenBounds.size.height;

	AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
	UIView *activeField = [self findFirstResponder:self.view];
	CGRect rectField = [activeField convertRect:activeField.bounds toView:delegate.window];

	if ((rectField.origin.y + rectField.size.height) > (screenHeight - keyboardFrameEnd.size.height - 10)) {
		// テキストフィールドがキーボードで隠れるようなら
		// 選択中のテキストフィールドの直ぐ下にキーボードの上端が付くように、スクロールビューの位置を上げる
		[UIView animateWithDuration:0.3
						 animations:^{
							 self.view.frame = CGRectMake(0, screenHeight - rectField.origin.y - rectField.size.height - keyboardFrameEnd.size.height - 10, self.view.frame.size.width, self.view.frame.size.height);
						 }];
	}
}

- (void)keyboardWillHidden:(NSNotification *)notification {
	// viewのy座標を元に戻してキーボードをしまう
	[UIView animateWithDuration:0.2
					 animations:^{
						 self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
					 }];
}

- (UIView *)findFirstResponder:(UIView *)view
{
	if ([view isFirstResponder]) {
		return view;
	}
	for (UIView *subView in[view subviews]) {
		if ([subView isFirstResponder]) {
			return subView;
		}
		if ([self findFirstResponder:subView]) {
			return [self findFirstResponder:subView];
		}
	}
	return nil;
}

@end
