//
//  JPGameListViewController.h
//  JeopardyHost
//
//  Created by Parker Wightman on 12/23/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPGameListViewController : UITableViewController

@property (strong, nonatomic) void (^didSelectBoard)(NSString *board);

@end
