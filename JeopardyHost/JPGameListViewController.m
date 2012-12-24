//
//  JPGameListViewController.m
//  JeopardyHost
//
//  Created by Parker Wightman on 12/23/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPGameListViewController.h"

@interface JPGameListViewController ()

@property (strong, nonatomic) NSArray *gameList;

@end

@implementation JPGameListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Games" ofType:@"plist"];
	_gameList = [NSArray arrayWithContentsOfFile:path];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _gameList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	cell.textLabel.text = [_gameList objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *path = [[NSBundle mainBundle] pathForResource:[_gameList objectAtIndex:indexPath.row] ofType:@"txt"];
	_didSelectBoard(path);
}

@end
