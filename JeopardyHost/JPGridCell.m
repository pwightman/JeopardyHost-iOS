//
//  JPGridCell.m
//  JeopardyHost
//
//  Created by Parker Wightman on 12/21/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPGridCell.h"
#import <QuartzCore/QuartzCore.h>

@interface JPGridCell ()
@property (strong, nonatomic) UILabel *label;
@end

@implementation JPGridCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_label = [[UILabel alloc] initWithFrame:CGRectZero];
		_label.numberOfLines = 4;
		_label.minimumScaleFactor = 0.3;
		_label.backgroundColor = [UIColor blueColor];
		_label.layer.borderColor = [UIColor blackColor].CGColor;
		_label.layer.borderWidth = 1;
		_label.textAlignment = NSTextAlignmentCenter;
		_label.textColor = [UIColor colorWithRed:0.99 green:0.63 blue:0.00 alpha:1.0];
		_label.font = [UIFont boldSystemFontOfSize:17];
		_label.shadowColor = [UIColor blackColor];
		_label.shadowOffset = CGSizeMake(0, 1);
		self.userInteractionEnabled = YES;
		_label.userInteractionEnabled = YES;
//		[_label addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
		[_label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
																		action:@selector(tapped)]];
		[self addSubview:_label];
    }
    return self;
}

- (void) layoutSubviews {
	_label.frame = self.bounds;
	_label.text = _text;
}

- (void) tapped {
	if (_didSelect) _didSelect();
}

@end
