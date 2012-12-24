//
//  JPNetworkManager.h
//  Jeopardy
//
//  Created by Parker Wightman on 12/16/12.
//  Copyright (c) 2012 Parker Wightman Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/AsyncSocket.h>

@interface JPNetworkManager : NSObject <AsyncSocketDelegate>

@property (nonatomic, strong) void (^didSignIn)(NSInteger identifier);
@property (nonatomic, strong) void (^didBeginBuzzing)();
@property (nonatomic, strong) void (^didStopBuzzing)();
@property (nonatomic, strong) void (^didBuzzIn)(NSString *name);
@property (nonatomic, strong) void (^didEndBuzzing)();
@property (nonatomic, strong) void (^didChooseQuestion)(NSString *question, NSString *answer);
@property (nonatomic, strong) void (^didReceiveScoreUpdate)(NSArray *names, NSArray *scores);
@property (nonatomic, strong) void (^didReceiveBoardUpdate)(NSArray *board);
@property (nonatomic, strong) void (^didReceiveDailyDouble)(NSString *question, NSString *answer);
@property (nonatomic, strong) void (^didDisconnect)();
@property (nonatomic, strong) void (^didConnect)();

- (void) connectWithIp:(NSString *)ip;
- (void) sendDisplayDailyDouble;
- (void) sendAnswer:(BOOL)isCorrect;
- (void) sendQuestionChosenAtColumn:(NSInteger)col row:(NSInteger)row;
- (void) sendFileInfo:(NSString *)path round:(NSInteger)round;
- (void) sendScoreChange:(NSString *)name amount:(NSString *)amount;
- (void) sendBeginBuzzing;
- (void) sendThinking;
- (void) sendReadyNext;
- (void) sendDailyDoubleAnswer:(BOOL)isCorrect;
- (void) disconnect;
- (void) reconnect;
	
@end
