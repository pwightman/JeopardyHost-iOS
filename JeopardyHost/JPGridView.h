//
//  JPGridView.h
//  JeopardyHost
//
//  Created by Parker Wightman on 12/21/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPGridView : UIView

@property (strong, nonatomic) NSString *(^textForColumnAndRow)(NSInteger col, NSInteger row);
@property (strong, nonatomic) void (^didSelectCell)(NSInteger col, NSInteger row);

- (void) reloadData;

@end
