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
#import "TDSession.h"
#import <AVFoundation/AVFoundation.h>


static NSString * ServiceName = @"crowdspeakDemo";

@interface CSSpeakerViewController () <MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCNearbyServiceAdvertiser * advertiser;
@property (nonatomic, strong) TDSession * session;
@property (nonatomic, strong) TDAudioOutputStreamer * outputStreamer;

@end


@implementation CSSpeakerViewController


- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.qrImageView.image = [CSQRGenerator imageWithString:ServiceName];
    //self.session = [[TDSession alloc] initWithPeerDisplayName:ServiceName];
}


- (void) viewDidAppear:(BOOL)animated
{
    [self startBroadcasting];
    [super viewWillAppear:animated];
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        NSLog(@"OK, we can record");
    }];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [self stopBroadcasting];
    [super viewWillDisappear:animated];
}


- (void) startRecording
{
    TDSession * session = self.session;
    self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[session outputStreamForPeer:session.connectedPeers[0]]];
    [self.outputStreamer streamAudioFromMic];
    [self.outputStreamer start];
}


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


#pragma mark MCNearbyServiceAdvertiserDelegate


- (void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"Got invitation");
    invitationHandler(YES, self.session.session);
}


@end
