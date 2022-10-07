//
//  CtComboBox.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/01.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtComboBox.h"

#define LIST_HIGHT  40.0

@interface CtComboBoxItem : NSObject

@property (nonatomic) NSString *itemText;
@property (nonatomic) int itemData;

@end

@interface CtComboBoxList : UITableView <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *_table;
}

@property (nonatomic) CtComboBox *comboBox;

@end

@interface CtComboBox ()
{
	CtComboBoxList *_comboBoxList;
}
@end

@implementation CtComboBox

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1.5f;
    self.layer.cornerRadius = 6.0f;
//    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
//    self.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
    [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    _items = [[NSMutableArray alloc] init];
    _selectedIndex = -1;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Drawing a triangle
    NSUInteger width = rect.size.height / 3;
    NSUInteger height = rect.size.height / 5;
    CGRect circleRect = CGRectMake(rect.size.width - (width + 10), (rect.size.height - height) / 2, width, height);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, CGRectGetMinX(circleRect), CGRectGetMinY(circleRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(circleRect), CGRectGetMinY(circleRect));
    CGContextAddLineToPoint(context, CGRectGetMidX(circleRect), CGRectGetMaxY(circleRect));
    CGContextClosePath(context);
    
	CGContextSetFillColorWithColor(context, self.enabled ? [UIColor grayColor].CGColor : [UIColor lightGrayColor].CGColor);

    CGContextFillPath(context);
}

- (int)addItem:(NSString *)itemText :(int)itemData
{
    CtComboBoxItem *item = [[CtComboBoxItem alloc] init];
    item.itemText = itemText;
    item.itemData = itemData;
    [_items addObject:item];
    
    return (int)_items.count - 1;
}

- (void)resetContent
{
    [_items removeAllObjects];
    
    [self setTitle:@"" forState:UIControlStateNormal];
}

- (void)setSelectedIndex:(int)selectedIndex
{
    _selectedIndex = selectedIndex;
    
    if (selectedIndex >= 0 && selectedIndex < _items.count)
        [self setTitle:((CtComboBoxItem *)_items[selectedIndex]).itemText forState:UIControlStateNormal];
}

- (int)selectedItemData
{
    if (_selectedIndex == -1)
        return -1;
    
    CtComboBoxItem *item = _items[_selectedIndex];
    return item.itemData;
}

- (void)setSelectedItemData:(int)itemData
{
    [_items enumerateObjectsUsingBlock:^(CtComboBoxItem *item, NSUInteger idx, BOOL *stop) {
        if (item.itemData == itemData) {
            self.selectedIndex = (int)idx;
            *stop = YES;
        }
    }];
}

- (void)buttonPressed:(id)sender
{
    UIView *topView = [UIApplication sharedApplication].keyWindow;
    CGRect rectComboButton = [self convertRect:self.bounds toView:topView];

    CGRect rectComboList;
    int upperHeight = rectComboButton.origin.y;
    int lowerHeight = topView.bounds.size.height - (rectComboButton.origin.y + rectComboButton.size.height);
    if (upperHeight > lowerHeight && lowerHeight < _items.count * LIST_HIGHT) {
        CGFloat height = MIN((int)(upperHeight / LIST_HIGHT) - 1, _items.count) * LIST_HIGHT;
        rectComboList = CGRectMake(rectComboButton.origin.x, rectComboButton.origin.y - height, rectComboButton.size.width + 10, height);
    } else {
        CGFloat height = MIN((int)(lowerHeight / LIST_HIGHT) - 1, _items.count) * LIST_HIGHT;
        rectComboList = CGRectMake(rectComboButton.origin.x, rectComboButton.origin.y + rectComboButton.size.height, rectComboButton.size.width + 10, height);
    }

    _comboBoxList = [[CtComboBoxList alloc] initWithFrame:rectComboList];
    _comboBoxList.comboBox = self;
    _comboBoxList.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    [topView addSubview:_comboBoxList];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)changeSelectedItem:(int)index
{
    [self setSelectedIndex:index];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    //[ownerViewController performSelector:targetSelector withObject:self];
}
#pragma clang diagnostic pop

@end

@implementation CtComboBoxItem

@end

@implementation CtComboBoxList

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.rowHeight = LIST_HIGHT;
        self.bounces = NO;
        //[self setBackgroundColor:[UIColor clearColor]];
        self.delegate = self;
        self.dataSource = self;
        self.showsVerticalScrollIndicator = YES;
    }
    return self;
}

- (void)didMoveToSuperview
{
    [self flashScrollIndicators];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _comboBox.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ComboBoxCell";
    
    // Important: Don't check the nil comparisson to reload the cell everytime
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    
    // Enable cell selection
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    //cell.detailTextLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
    // Defining text label
    cell.textLabel.text = ((CtComboBoxItem *)_comboBox.items[indexPath.row]).itemText;

    if (indexPath.row == _comboBox.selectedIndex)
        cell.textLabel.textColor = self.tintColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_comboBox changeSelectedItem:(int)indexPath.row];
    [self removeFromSuperview];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (![self pointInside:point withEvent:event]) {
        [self removeFromSuperview];
    }

    return [super hitTest:point withEvent:event];
}

@end
