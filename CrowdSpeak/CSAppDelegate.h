//
//  CSAppDelegate.h
//  CrowdSpeak
//
//  Created by Dan Treiman on 3/6/14.
//  Copyright (c) 2014 W3C. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MCPeerID;


@interface CSAppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) MCPeerID * peerID;
@property (strong, nonatomic) UIWindow * window;

@end
