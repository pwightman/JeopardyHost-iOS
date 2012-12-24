//
//  JPGridCell.h
//  JeopardyHost
//
//  Created by Parker Wightman on 12/21/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPGridCell : UIView

@property (assign, nonatomic) NSInteger col;
@property (assign, nonatomic) NSInteger row;
@property (strong, nonatomic) NSString *text;

@property (strong, nonatomic) void (^didSelect)();

@end
