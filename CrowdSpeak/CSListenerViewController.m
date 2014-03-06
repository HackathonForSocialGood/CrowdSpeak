//
//  CSListenerViewController.m
//  CrowdSpeak
//
//  Created by Dan Treiman on 3/6/14.
//  Copyright (c) 2014 W3C. All rights reserved.
//

#import "CSListenerViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CSQRGenerator.h"
#import "ZBarReaderViewController.h"
#import "CSAppDelegate.h"
#import "TDAudioInputStreamer.h"


@interface CSListenerViewController () <ZBarReaderDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@property (nonatomic, copy) NSString * code;
@property (nonatomic, strong) MCSession * session;
@property (nonatomic, strong) MCNearbyServiceBrowser * browser;
@property (nonatomic, strong) TDAudioInputStreamer * player;

@end


@implementation CSListenerViewController


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.code == nil) {
        ZBarReaderViewController * reader = [[ZBarReaderViewController alloc] init];
        reader.readerDelegate = self;
        [self presentViewController:reader animated:NO completion:NULL];
    }
}


- (void) recievedQRCode
{
    if (self.code) {
        self.qrImageView.image = [CSQRGenerator imageWithString:self.code];
    }
    
    CSAppDelegate * appDelegate = (CSAppDelegate *)[UIApplication sharedApplication].delegate;
    MCPeerID * peerID = appDelegate.peerID;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:self.code];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}


#pragma mark ZBarReaderDelegate


- (void) imagePickerController: (UIImagePickerController *) reader
 didFinishPickingMediaWithInfo: (NSDictionary *) info
{
    // ADD: get the decode results
    id<NSFastEnumeration> results =
    [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol * symbol = nil;
    for(symbol in results) {
        self.code = symbol.data;
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [self recievedQRCode];
    }];
}


#pragma mark MCNearbyServiceBrowserDelegate


- (void) browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Did not start browsing");
}


- (void) browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    if (self.session == nil) {
        MCSession * session = [[MCSession alloc] initWithPeer:peerID
                                             securityIdentity:nil
                                         encryptionPreference:MCEncryptionNone];
        session.delegate = self;
        self.session = session;
    }
    [browser invitePeer:peerID toSession:self.session withContext:[@"Hello" dataUsingEncoding:NSUTF8StringEncoding] timeout:30];
}


- (void) browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Listener: lost peer");
}


#pragma mark MCSessionDelegate


- (void) session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateNotConnected) {
        self.session = nil;
        NSLog(@"Listener: Not connected");
    }
    else if (state == MCSessionStateConnected) {
        // start listening for data
        NSLog(@"Listener: Connected");
    }
}


- (void) session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString * message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@""
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}


- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSUInteger)buttonIndex
{
    
}

//- (void)session:(MCSession *)session
//didReceiveStream:(NSInputStream *)stream
//       withName:(NSString *)streamName
//       fromPeer:(MCPeerID *)peerID
//{
//    NSLog(@"Listener: Got a stream");
//    self.player = [[TDAudioInputStreamer alloc] initWithInputStream:stream];
//    [self.player start];
//}



@end
