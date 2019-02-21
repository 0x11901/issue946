//
//  ViewController.m
//  socket-test
//
//  Created by Xinling on 2019/2/18.
//  Copyright © 2019 上海友玩网络科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import <SocketRocket/SocketRocket.h>

#define USE_WEBSOCKET 1

const NSInteger kMaxClient = 100;

@interface ViewController () <GCDAsyncSocketDelegate, SRWebSocketDelegate>

@end

@implementation ViewController
{
    NSTimer* _createTimer;
    NSMutableArray* sockets;
    NSMutableDictionary<NSNumber*, NSDate*>* startDate;
    NSInteger index;
    CGFloat totalTime;
    CGFloat times;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sockets = [[NSMutableArray alloc] init];
    index = 0;
    totalTime = 0;
    times = 0;
    startDate = [[NSMutableDictionary alloc] init];
    // Do any additional setup after loading the view.
#if 1 == USE_WEBSOCKET
    _createTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(createwebsocket:) userInfo:nil repeats:YES];
#else
    _createTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(createSocket:) userInfo:nil repeats:YES];
#endif
    [[NSRunLoop currentRunLoop] addTimer:_createTimer forMode:NSDefaultRunLoopMode];
    
    [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"%f=", self->totalTime / self->times);
    }];
}

- (void)createwebsocket:(CGFloat)f
{
    SRWebSocket* webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://127.0.0.1:8001"]];
//    SRWebSocket* webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://172.21.14.63:8001"]];
    webSocket.delegate = self;
    [webSocket open];
//    NSLog(@"createwebsocket %lu", (unsigned long)webSocket.hash);

    [sockets addObject:webSocket];
    
    index ++;
    if (index >= kMaxClient)
    {
        [_createTimer invalidate];
    }

}

- (void)createSocket:(CGFloat)f
{
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    GCDAsyncSocket* asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
    NSError *error = nil;
    if (![asyncSocket connectToHost:@"127.0.0.1" onPort:8001 error:&error])
    {
        NSLog(@"%@", error);
        return;
    }
    
    [sockets addObject:asyncSocket];
    
    index ++;
    if (index >= kMaxClient)
    {
        [_createTimer invalidate];
    }
}

- (void)sendMessage:(CGFloat)f
{
    
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"%s  %p", __FUNCTION__, sock);
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"%s  %p", __FUNCTION__, sock);
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];

//    double delayInSeconds = 1.0;
//    dispatch_time_t delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds*NSEC_PER_SEC);
//    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_after(delayInNanoSeconds, concurrentQueue, ^{
//        NSString* msg = @"hdsakjhdshfjkdsfhjk";
//        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:100 tag:0];
////        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
////        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
////        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
////        [sock writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
//    });
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%s  %p", __FUNCTION__, sock);
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"%s  %p", __FUNCTION__, sock);
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"%s  %p", __FUNCTION__, sock);
}


///--------------------------------------
#pragma mark - SRWebSocketDelegate
///--------------------------------------
                    
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
//    NSLog(@"Websocket Connected");
    [webSocket send:@"{\"cmd\":\"connector.entryHandler.entry\",\"data\":{}}"];
    [startDate setObject:[NSDate date] forKey:@(webSocket.hash)];
    [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [webSocket send:@"{\"cmd\":\"area.playerHandler.move\",\"data\":{}}"];
        [self->startDate setObject:[NSDate date] forKey:@(webSocket.hash)];
//        NSLog(@"send %ld", webSocket.hash);
    }];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    [sockets removeObject:webSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(nonnull NSString *)string
{
    NSLog(@"Received \"%@\"", string);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    [sockets removeObject:webSocket];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"WebSocket received pong");
}
                  
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
//    NSLog(@"Received  %ld", webSocket.hash);
    NSDate* start = startDate[@(webSocket.hash)];
    if (start)
    {
        CGFloat t = [[NSDate date] timeIntervalSinceDate:start];
        [startDate removeObjectForKey:@(webSocket.hash)];
        if (t > 0)
        {
            times++;
            totalTime += t;
        }
    }
}

                    
@end
