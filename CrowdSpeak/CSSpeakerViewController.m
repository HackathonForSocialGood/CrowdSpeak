//
//  CSSpeakerViewController.m
//  CrowdSpeak
//
//  Created by Dan Treiman on 3/6/14.
//  Copyright (c) 2014 W3C. All rights reserved.
//

#import "CSSpeakerViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CSQRGenerator.h"
#import "CSAppDelegate.h"
#import "TDAudioOutputStreamer.h"
#import <AVFoundation/AVFoundation.h>
#import <GameKit/GameKit.h>


static NSString * ServiceName = @"crowdspeakDemo";

@interface CSSpeakerViewController () <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser * advertiser;
@property (nonatomic, strong) MCSession * session;
@property (nonatomic, strong) TDAudioOutputStreamer * outputStreamer;

@end


@implementation CSSpeakerViewController


- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.qrImageView.image = [CSQRGenerator imageWithString:ServiceName];
//    self.session = [[TDSession alloc] initWithPeerDisplayName:ServiceName];
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
    }];
    [self startBroadcasting];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [self stopBroadcasting];
    [super viewWillDisappear:animated];
}


//- (void) startRecording
//{
//    TDSession * session = self.session;
//    self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[session outputStreamForPeer:session.connectedPeers[0]]];
//    [self.outputStreamer streamAudioFromMic];
//    [self.outputStreamer start];
//}


- (IBAction) startBroadcasting
{
    CSAppDelegate * appDelegate = (CSAppDelegate *)[UIApplication sharedApplication].delegate;
    MCPeerID * peerID = appDelegate.peerID;
    MCNearbyServiceAdvertiser * advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:peerID
                                                                               discoveryInfo:nil
                                                                                 serviceType:ServiceName];
    advertiser.delegate = self;
    [advertiser startAdvertisingPeer];
    self.advertiser = advertiser;
}


- (IBAction) stopBroadcasting
{
    [self.advertiser stopAdvertisingPeer];
    self.advertiser = nil;
}


- (IBAction) textMessage:(id)sender
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Send a Message", @"Alert Title.")
                                                     message:NSLocalizedString(@"", @"Alert Message.")
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK", @"Button Title")
                                           otherButtonTitles:NSLocalizedString(@"Cancel", @"Button Title"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
    [alert show];
}


- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSString * message = [alertView textFieldAtIndex:0].text;
        if ([message length] == 0) {
            // If the user entered no text, do nothing
            return;
        }
        [self sendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    }
}


#pragma mark MCNearbyServiceAdvertiserDelegate


- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)remotePeerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    if (self.session == nil) {
        CSAppDelegate * appDelegate = (CSAppDelegate *)[UIApplication sharedApplication].delegate;
        MCPeerID * peerID = appDelegate.peerID;
        self.session = [[MCSession alloc] initWithPeer:peerID];
        self.session.delegate = self;
    }
    NSLog(@"Handle invitation");
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        invitationHandler(YES, self.session);
    });

////        invitationHandler(YES, self.session);
////    }
////    else {
//        [self.session nearbyConnectionDataForPeer:remotePeerID
//                            withCompletionHandler:^(NSData *connectionData, NSError * error) {
//                                [self.session connectPeer:remotePeerID withNearbyConnectionData:connectionData];
//                        invitationHandler(YES, self.session);
//                    }];
////    }
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnecting) {
        NSLog(@"Connecting to %@", peerID.displayName);
    } else if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"Disconnected from %@", peerID.displayName);
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
}


- (void) sendData:(NSData *)data
{
    NSError *error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"Error: %@", error.userInfo.description);
    }
}


@end
