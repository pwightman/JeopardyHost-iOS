//
//  JPViewController.m
//  JeopardyHost
//
//  Created by Parker Wightman on 12/20/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPViewController.h"
#import "JPGridView.h"
#import "JPNetworkManager.h"
#import "JPGameListViewController.h"
#import <MTBlockTableView/MTBlockTableView.h>
#import <PSPDFAlertView.h>
#import <PSPDFActionSheet.h>

typedef NS_ENUM(NSInteger, JPState) {
	JPStatePreGame,
	JPStateReadyForQuestion,
	JPStatePosingQuestion,
	JPStateWaitingForBuzz,
	JPStateStoppedBuzzing,
	JPStateEndedBuzzing,
	JPStateDisconnected,
	JPStateWaitingForDailyDoubleAnswer
};

@interface JPViewController ()

@property (strong, nonatomic) IBOutlet UIButton *loadGameButton;
@property (strong, nonatomic) IBOutlet MTBlockTableView *playerTableView;
@property (strong, nonatomic) IBOutlet JPGridView *gridView;
@property (strong, nonatomic) IBOutlet UILabel *whoBuzzedInLabel;
@property (strong, nonatomic) IBOutlet UILabel *answerLabel;
@property (strong, nonatomic) IBOutlet UILabel *connectedLabel;
@property (strong, nonatomic) IBOutlet UIView *coloredView;

@property (strong, nonatomic) IBOutlet UIButton *startBuzzingButton;
@property (strong, nonatomic) IBOutlet UIButton *thinkButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *incorrectButton;
@property (strong, nonatomic) IBOutlet UIButton *correctButton;
@property (strong, nonatomic) IBOutlet UIButton *loadButton;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;

@property (strong, nonatomic) JPNetworkManager *networkManager;
@property (strong, nonatomic) NSArray *board;
@property (strong, nonatomic) UIView *questionView;
@property (strong, nonatomic) NSArray *scores;
@property (strong, nonatomic) NSArray *names;
@property (assign, nonatomic) JPState state;

@end

@implementation JPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	_networkManager = [[JPNetworkManager alloc] init];
	[self presentNetworkConnectDialog];
//	[_networkManager connectWithIp:@"127.0.0.1"];
	[self setupNetworkBlocks];
	[self setupTableViewBlocks];
	[self setupGridViewBlocks];
	_scores = @[];
	_names = @[];
	[self transitionTo:JPStateDisconnected];
}

- (void) transitionTo:(JPState)state {
	[self willTransitionFromState:_state toState:state];
	_state = state;
	static NSArray *buttons = nil;
	
	if (!buttons) {
		buttons = @[
		_loadButton,
		_startBuzzingButton,
		_thinkButton,
		_nextButton,
		_correctButton,
		_incorrectButton
		];
	}
	
	for (UIButton *button in buttons) {
		BOOL enabled = [self isButton:button enabledForState:state];
		if (enabled) button.alpha = 1.0;
		else		 button.alpha = 0.5;
		button.enabled = enabled;
	}
	
	if (state == JPStateWaitingForBuzz) {
		_coloredView.backgroundColor = [UIColor greenColor];
	} else {
		_coloredView.backgroundColor = [UIColor redColor];
	}
}

- (BOOL) isButton:(UIView *)button enabledForState:(JPState)state {
	if (button == _loadButton) {
		return (state == JPStatePreGame || state == JPStateReadyForQuestion);
	}
	if (button == _startBuzzingButton) {
		return (state == JPStatePosingQuestion);
	}
	if (button == _thinkButton) {
		return YES;
	}
	if (button == _nextButton) {
		return (state == JPStateEndedBuzzing);
	}
	if (button == _correctButton || button == _incorrectButton) {
		return (state == JPStateStoppedBuzzing || state == JPStateWaitingForDailyDoubleAnswer);
	}
	
	return NO;
}

- (void) willTransitionFromState:(JPState)fromState toState:(JPState)toState {
	if (toState == JPStatePreGame) {
		_loadButton.enabled = YES;
		_correctButton.enabled = NO;
		
	}
}

- (void) setupNetworkBlocks {
	BlockSelf
	_networkManager.didConnect = ^{
		_connectedLabel.text = @"Connected!";
		[blockSelf transitionTo:JPStatePreGame];
	};
	
	_networkManager.didReceiveScoreUpdate = ^(NSArray *names, NSArray *scores) {
		blockSelf.names = names;
		blockSelf.scores = scores;
		[blockSelf.playerTableView reloadData];
	};
	
	_networkManager.didDisconnect = ^{
		_connectedLabel.text = @"Disconnected! Try reconnecting";
		[blockSelf transitionTo:JPStateDisconnected];
	};
	
	_networkManager.didReceiveBoardUpdate = ^(NSArray *board) {
		blockSelf.board = board;
		[blockSelf transitionTo:JPStateReadyForQuestion];
		[blockSelf.gridView reloadData];
	};
	
	_networkManager.didChooseQuestion = ^(NSString *question, NSString *answer) {
		_answerLabel.text = answer;
		[blockSelf transitionTo:JPStatePosingQuestion];
		[blockSelf showQuestionWithText:question];
	};
	
	_networkManager.didBeginBuzzing = ^{
		[blockSelf transitionTo:JPStateWaitingForBuzz];
	};
	
	_networkManager.didBuzzIn = ^(NSString *name){
		blockSelf.whoBuzzedInLabel.text = name;
		[blockSelf transitionTo:JPStateStoppedBuzzing];
		[blockSelf blinkBuzzIn];
	};
	
	_networkManager.didEndBuzzing = ^{
		[blockSelf transitionTo:JPStateEndedBuzzing];
	};
	
	_networkManager.didReceiveDailyDouble = ^(NSString *question, NSString *answer) {
		[blockSelf showQuestionWithText:question];
		_answerLabel.text = answer;
		[blockSelf transitionTo:JPStateWaitingForDailyDoubleAnswer];
	};
}

- (void) blinkBuzzIn {
	[UIView animateWithDuration:0.1 animations:^{
		_coloredView.transform = CGAffineTransformMakeScale(1.3, 1.3);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.1 animations:^{
			_coloredView.transform = CGAffineTransformMakeScale(1.0, 1.0);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.1 animations:^{
				_coloredView.transform = CGAffineTransformMakeScale(1.3, 1.3);
			} completion:^(BOOL finished) {
				_coloredView.transform = CGAffineTransformMakeScale(1.0, 1.0);
			}];
		}];
	}];
}

- (void) showQuestionWithText:(NSString *)text {
	_questionView = [[UIView alloc] initWithFrame:_gridView.frame];
	_questionView.backgroundColor = [UIColor blueColor];
	UILabel *questionLabel = [[UILabel alloc] initWithFrame:_gridView.frame];
	questionLabel.backgroundColor = [UIColor blueColor];
	questionLabel.font = [UIFont boldSystemFontOfSize:30];
	questionLabel.textColor = [UIColor whiteColor];
	questionLabel.shadowOffset = CGSizeMake(0, 1);
	questionLabel.shadowColor = [UIColor blackColor];
	questionLabel.numberOfLines = 10;
	questionLabel.minimumScaleFactor = 0.3;
	questionLabel.adjustsFontSizeToFitWidth = YES;
	questionLabel.text = text;
	questionLabel.textAlignment = NSTextAlignmentCenter;
	questionLabel.frame = CGRectInset(_questionView.bounds, 10, 10);
	[_questionView addSubview:questionLabel];
	[self.view addSubview:_questionView];
}

- (void) dismissQuestion {
	[_questionView removeFromSuperview];
	_questionView = nil;
}

- (void) setupTableViewBlocks {
	BlockSelf
	[_playerTableView setNumberOfRowsInSectionBlock:^NSInteger(UITableView *tableView, NSInteger section) {
		return _names.count;
	}];
	
	[_playerTableView setCellForRowAtIndexPathBlock:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		cell.textLabel.text = [_names objectAtIndex:indexPath.row];
		cell.detailTextLabel.text = [_scores objectAtIndex:indexPath.row];
		return cell;
	}];
	
	[_playerTableView setDidSelectRowAtIndexPathBlock:^(UITableView *tableView, NSIndexPath *indexPath) {
		NSString *name = [blockSelf.names objectAtIndex:indexPath.row];
		PSPDFAlertView *alertView = [[PSPDFAlertView alloc] initWithTitle:@"Score Change" message:[NSString stringWithFormat:@"Change %@ score to...", name]];
		__block __weak typeof(alertView) blockAlertView = alertView;
		alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
		[alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
		
		[alertView addButtonWithTitle:@"Cancel" block:^{
		}];
		
		[alertView addButtonWithTitle:@"Change" block:^{
			[blockSelf.networkManager sendScoreChange:name
											   amount:[blockAlertView textFieldAtIndex:0].text];
		}];
		
		[alertView show];
		
	}];
}

- (void) setupGridViewBlocks {
	BlockSelf
	_gridView.didSelectCell = ^(NSInteger col, NSInteger row) {
		// You need to adjust for the headers
		row += 1;
		if ([[[blockSelf.board objectAtIndex:col] objectAtIndex:row] isEqualToString:@""]) return;
		[blockSelf.networkManager sendQuestionChosenAtColumn:col row:row - 1];
		[[blockSelf.board objectAtIndex:col] setObject:@"" atIndex:row];
		[blockSelf.gridView reloadData];
	};
	
	_gridView.textForColumnAndRow = ^NSString *(NSInteger col, NSInteger row) {
		if (!blockSelf.board) return @"";
		
		return [[blockSelf.board objectAtIndex:col] objectAtIndex:row];
	};
}

- (void) loadFilePath:(NSString *)path {
	[_networkManager sendFileInfo:[[NSBundle mainBundle] pathForResource:path ofType:@"txt"] round:1];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"gameList"]) {
		JPGameListViewController *controller = (JPGameListViewController *)segue.destinationViewController;
		
		controller.didSelectBoard = ^(NSString *path){
			PSPDFAlertView *alertView = [[PSPDFAlertView alloc] initWithTitle:@"Round" message:@"What round is this?"];
			[alertView addButtonWithTitle:@"Round 1" block:^{
				[_networkManager sendFileInfo:path round:1];
			}];
			
			[alertView addButtonWithTitle:@"Round 2" block:^{
				[_networkManager sendFileInfo:path round:2];
			}];
			
			[alertView show];
			[[(UIStoryboardPopoverSegue *)segue popoverController] dismissPopoverAnimated:YES];
		};
		
	}
}

- (IBAction)loadGameTapped:(id)sender {
}

- (IBAction)correctTapped:(id)sender {
	if (_state == JPStateWaitingForDailyDoubleAnswer) {
		[_networkManager sendDailyDoubleAnswer:YES];
		[self transitionTo:JPStateEndedBuzzing];
	}
	else
		[_networkManager sendAnswer:YES];
}

- (IBAction)incorrectTapped:(id)sender {
	if (_state == JPStateWaitingForDailyDoubleAnswer) {
		[_networkManager sendDailyDoubleAnswer:NO];
		[self transitionTo:JPStateEndedBuzzing];
	}
	else
		[_networkManager sendAnswer:NO];
}

- (IBAction)nextTapped:(id)sender {
	[self transitionTo:JPStateReadyForQuestion];
	[_networkManager sendReadyNext];
	[self dismissQuestion];
}

- (IBAction)startBuzzingTapped:(id)sender {
	[_networkManager sendBeginBuzzing];
}

- (IBAction)thinkTapped:(id)sender {
	[_networkManager sendThinking];
}

- (IBAction)connectTapped:(id)sender {
	if (_networkManager) {
		PSPDFActionSheet *actionSheet = [[PSPDFActionSheet alloc] initWithTitle:@"Would you like to reconnect to the current server, or a new one?"];
		
		[actionSheet addButtonWithTitle:@"Reconnect" block:^{
			[_networkManager reconnect];
		}];
		
		[actionSheet addButtonWithTitle:@"New Connection" block:^{
			[self presentNetworkConnectDialog];
		}];
		
		[actionSheet addButtonWithTitle:@"Cancel" block:^{
			
		}];
		
		[actionSheet showInView:_connectButton];
	} else {
		[self presentNetworkConnectDialog];
	}
}

- (void) presentNetworkConnectDialog {
	if (_networkManager) [_networkManager disconnect];
	
	_networkManager = [[JPNetworkManager alloc] init];
	
	PSPDFAlertView *alertView = [[PSPDFAlertView alloc] initWithTitle:@"IP Address" message:@"What IP Address should I connect to?"];
	
	[alertView addButtonWithTitle:@"Cancel" block:^{
	}];
	
	[alertView addButtonWithTitle:@"Connect" block:^{
		NSString *host = [alertView textFieldAtIndex:0].text;
		[_networkManager connectWithIp:host];
	}];
	
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	
	[alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	
	[alertView show];
	
	[self setupNetworkBlocks];
}

- (void) reconnect {
	[_networkManager reconnect];
}

@end
