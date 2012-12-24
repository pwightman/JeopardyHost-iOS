//
//  JPGridView.m
//  JeopardyHost
//
//  Created by Parker Wightman on 12/21/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPGridView.h"
#import "JPGridCell.h"

#define JP_GRID_COLUMN_SIZE 6
#define JP_GRID_ROW_SIZE 6

@interface JPGridView ()
@property (strong, nonatomic) NSMutableArray *cells;
@end

@implementation JPGridView

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	
	return self;
}

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	
	return self;
}

- (void) setup {
	self.userInteractionEnabled = YES;
	_cells = [NSMutableArray array];
	for (NSInteger i = 0; i < JP_GRID_COLUMN_SIZE; i++) {
		[_cells addObject:[NSMutableArray array]];
		for (NSInteger j = 0; j < JP_GRID_ROW_SIZE; j++) {
			JPGridCell *cell = [[JPGridCell alloc] initWithFrame:CGRectZero];
			[[_cells objectAtIndex:i] addObject:cell];
			[self addSubview:cell];
		}
	}
}

- (void) reloadData {
	[self setNeedsLayout];
	for (NSArray *rows in _cells) {
		for (JPGridCell *cell in rows) {
			[cell setNeedsLayout];
		}
	}
}

- (void) layoutSubviews {
	for (NSInteger i = 0; i < JP_GRID_COLUMN_SIZE; i++) {
		NSArray *rows = [_cells objectAtIndex:i];
		for (NSInteger j = 0; j < JP_GRID_ROW_SIZE; j++) {
			JPGridCell *cell = [rows objectAtIndex:j];
			CGRect frame = CGRectZero;
			frame.size.width = self.frame.size.width / JP_GRID_COLUMN_SIZE;
			frame.size.height = self.frame.size.height / JP_GRID_ROW_SIZE;
			frame.origin.x = frame.size.width * i;
			frame.origin.y = frame.size.height * j;
			cell.frame = frame;
			cell.text = _textForColumnAndRow(i, j);
			if (j != 0) {
				cell.didSelect = ^{
					if (_didSelectCell) _didSelectCell(i, j - 1);
				};
			}
		}
	}
}

@end
