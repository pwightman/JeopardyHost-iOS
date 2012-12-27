//
//  JPNetworkManager.m
//  Jeopardy
//
//  Created by Parker Wightman on 12/16/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import "JPNetworkManager.h"

typedef NS_ENUM(NSInteger, JPNetworkProtocol) {
	JPNetworkProtocolStopBuzzing = 0,
	JPNetworkProtocolFileInfo = 1,
	JPNetworkProtocolChooseQuestion = 2,
	JPNetworkProtocolReadyNext = 3,
	JPNetworkProtocolAnswered = 4,
	JPNetworkProtocolBeginBuzzing = 5,
	JPNetworkProtocolPlayMusic = 6,
	JPNetworkProtocolChangeScore = 7,
	JPNetworkProtocolSignIn = 8,
	JPNetworkProtocolSignedIn = 9,
	JPNetworkProtocolBuzzIn = 10,
	JPNetworkProtocolSendBoard = 11,
	JPNetworkProtocolScoreUpdate = 12,
	JPNetworkProtocolEndBuzzing = 13,
	JPNetworkProtocolDailyDouble = 14,
	JPNetworkProtocolDisplayDailyDouble = 15,
	JPNetworkProtocolPlayTimerOutSound = 16,
	JPNetworkProtocolThinking = 17,
	JPNetworkProtocolReconnect = 18,
};

@interface JPNetworkManager	()

@property (nonatomic, strong) AsyncSocket *socket;
@property (atomic, strong) NSArray *data;
@property (nonatomic, strong) NSLock *readDataLock;
@property (nonatomic, strong) NSString *hostIp;

@end

@implementation JPNetworkManager

- (id) init {
	self = [super init];
	if (self) {
		_socket = [[AsyncSocket alloc] initWithDelegate:self];
		_readDataLock = [[NSLock alloc] init];
		_data = @[];
	}
	
	return self;
}

- (void) connectWithIp:(NSString *)ip {
	
	if (_socket.isConnected) return;
	
	NSError *error = nil;
	
	[_socket connectToHost:ip onPort:3366 error:&error];
	
	_hostIp = ip;
	
	if (error) {
		@throw error.localizedDescription;
	}
	
	[self sendString:[NSString stringWithFormat:@"%d\nhost\n", JPNetworkProtocolSignIn]];
}

- (void) disconnect {
	[_socket disconnect];
}

- (void) reconnect {
	if (_socket.isConnected) return;
	
	NSError *error = nil;
	
	[_socket connectToHost:_hostIp onPort:3366 error:&error];
	
	if (error) {
		@throw error.localizedDescription;
	}
	
	[self sendString:[NSString stringWithFormat:@"%d\nhost\n", JPNetworkProtocolReconnect]];
}

- (void) sendBeginBuzzing {
	[self sendString:[NSString stringWithFormat:@"%d\n", JPNetworkProtocolBeginBuzzing]];
}

- (void) sendDailyDoubleAnswer:(BOOL)isCorrect {
	NSString *isCorrectString = (isCorrect ? @"correct" : @"incorrect");
	[self sendString:[NSString stringWithFormat:@"%d\n%@\n", JPNetworkProtocolDailyDouble, isCorrectString]];
}

- (void) sendDisplayDailyDouble {
	[self sendString:[NSString stringWithFormat:@"%d\n", JPNetworkProtocolDisplayDailyDouble]];
}

- (void) sendAnswer:(BOOL)isCorrect {
	NSString *correctString = (isCorrect ? @"correct" : @"incorrect");
	[self sendString:[NSString stringWithFormat:@"%d\n%@\n", JPNetworkProtocolAnswered, correctString]];
}

- (void) sendQuestionChosenAtColumn:(NSInteger)col row:(NSInteger)row {
	[self sendString:[NSString stringWithFormat:@"%d\n%d\n%d\n", JPNetworkProtocolChooseQuestion, col, row]];
}

- (void) sendFileInfo:(NSString *)path round:(NSInteger)round {
	NSString *file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	NSArray *splitFile = [file componentsSeparatedByString:@"\n"];
	[self sendString:[NSString stringWithFormat:@"%d\n%d\n%d\n", JPNetworkProtocolFileInfo, round, splitFile.count]];
	
	for (NSString *line in splitFile) {
		[self sendString:[line stringByAppendingString:@"\n"]];
	}
}

- (void) sendScoreChange:(NSString *)name amount:(NSString *)amount {
	[self sendString:[NSString stringWithFormat:@"%d\n%@\n%@\n", JPNetworkProtocolChangeScore, name, amount]];
}

- (void) sendThinking {
	[self sendString:[NSString stringWithFormat:@"%d\n", JPNetworkProtocolThinking]];
}

- (void) sendReadyNext {
	[self sendString:[NSString stringWithFormat:@"%d\n", JPNetworkProtocolReadyNext]];
}

- (void) sendString:(NSString *)string {
	[_socket writeData:[string dataUsingEncoding:NSUTF8StringEncoding] withTimeout:300 tag:1];
}

- (void) startReading {
	[_socket readDataWithTimeout:300 tag:1];
}

#define BOARD_COLUMN_SIZE 6
#define BOARD_ROW_SIZE    6

- (NSArray *) attemptParse:(NSArray *)data {
	NSInteger protocol = [[data objectAtIndex:0] integerValue];
	NSInteger unitsUsed = 0;
	NSMutableArray *playerNames = [@[] mutableCopy];
	NSMutableArray *playerScores = [@[] mutableCopy];
	NSInteger temp = 0;
	NSString *question = nil;
	NSString *answer = nil;
	NSMutableArray *board = [NSMutableArray arrayWithCapacity:6];
	NSString *name = nil;
	
	switch (protocol) {
		case JPNetworkProtocolSendBoard:
			if (data.count < 37) break;
			unitsUsed += 37;
			for (NSInteger i = 0; i < BOARD_COLUMN_SIZE; i++) {
				[board addObject:[NSMutableArray arrayWithCapacity:BOARD_ROW_SIZE]];
				for (NSInteger j = 0; j < BOARD_ROW_SIZE; j++) {
					[[board objectAtIndex:i] addObject:[data objectAtIndex:i*BOARD_ROW_SIZE + j + 1]];
				}
			}
			
			if (_didReceiveBoardUpdate) _didReceiveBoardUpdate(board);
			break;
		case JPNetworkProtocolBuzzIn:
			if (data.count < 2) break;
			name = [data objectAtIndex:1];
			unitsUsed += 2;
			if (_didBuzzIn) _didBuzzIn(name);
			break;
		case JPNetworkProtocolBeginBuzzing:
			unitsUsed += 1;
			NSLog(@"DB - Received Begin Buzzing");
			if (_didBeginBuzzing) _didBeginBuzzing();
			break;
		case JPNetworkProtocolStopBuzzing:
			unitsUsed += 1;
			NSLog(@"DB - Received Stop Buzzing");
			if (_didStopBuzzing) _didStopBuzzing();
			break;
		case JPNetworkProtocolEndBuzzing:
			unitsUsed += 1;
			NSLog(@"DB - Received Stop Buzzing");
			if (_didEndBuzzing) _didEndBuzzing();
			break;
		case JPNetworkProtocolDailyDouble:
			if (data.count < 3) break;
			question = [data objectAtIndex:1];
			answer = [data objectAtIndex:2];
			unitsUsed += 3;
			NSLog(@"DB - Received Daily Double, question: %@, answer %@", question, answer);
			if (_didReceiveDailyDouble) _didReceiveDailyDouble(question, answer);
			break;
		case JPNetworkProtocolScoreUpdate:
			if (data.count < 4) break;
			temp = [[data objectAtIndex:1] integerValue];
			if (data.count < temp*2 + 2) break;
			unitsUsed += 2;
			for (NSInteger i = 0; i < temp; i++) {
				[playerNames addObject:[data objectAtIndex:2 + i*2]];
				[playerScores addObject:[data objectAtIndex:3 + i*2]];
				unitsUsed += 2;
			}
			NSLog(@"DB - Received score update:\nnames: %@\n scores:%@", playerNames, playerScores);
			if (_didReceiveScoreUpdate) _didReceiveScoreUpdate(playerNames, playerScores);
			break;
		case JPNetworkProtocolChooseQuestion:
			if (data.count < 3) break;
			question = [data objectAtIndex:1];
			answer = [data objectAtIndex:2];
			unitsUsed += 3;
			if (_didChooseQuestion) _didChooseQuestion(question, answer);
			
			
		default:
			break;
	}
	
	return [self array:data objectsFromIndex:unitsUsed];
}

- (NSArray *) array:(NSArray *)array objectsFromIndex:(NSInteger)index {
	NSMutableArray *objs = [@[] mutableCopy];
	
	for (NSInteger i = index; i < array.count; i++) {
		[objs addObject:[array objectAtIndex:i]];
	}
	
	return objs;
}

/*
 10
 Alex
 
 13
 3
 
 12
 */

#pragma AsyncSocketDelegate

- (void) onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	if (_didConnect) _didConnect();
	[self startReading];
}

- (void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"NetworkManager didReadData called: %@", [NSString stringWithUTF8String:[data bytes]]);
	
	NSString *string = [NSString stringWithUTF8String:[data bytes]];
	
	[_readDataLock lock];
	
	NSArray *newData = [self.data arrayByAddingObjectsFromArray:[string componentsSeparatedByString:@"\n"]];
	NSMutableArray *newFilteredData = [@[] mutableCopy];
	
	[newData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSRange range = [obj rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
		NSString *result = [obj stringByReplacingCharactersInRange:range withString:@""];
		
		range = [obj rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];
		result = [obj stringByReplacingCharactersInRange:range withString:@""];
		if (![result isEqualToString:@""]) {
			[newFilteredData addObject:obj];
		}
	}];
	
	NSInteger newCount = 0;
	NSInteger currentCount = newFilteredData.count;
	
	do {
		currentCount = newFilteredData.count;
		self.data = newFilteredData = [[self attemptParse:newFilteredData] mutableCopy];
		newCount = newFilteredData.count;
	} while (currentCount != newCount && newCount != 0);
	
	[_readDataLock unlock];
	[self startReading];
	
}

- (void) onSocketDidDisconnect:(AsyncSocket *)sock {
	if (_didDisconnect) _didDisconnect();
	NSLog(@"disconnected");
}





@end
