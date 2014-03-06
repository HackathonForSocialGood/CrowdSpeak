//
//  CSQRGenerator.m
//  CrowdSpeak
//
//  Created by Dan Treiman on 3/6/14.
//  Copyright (c) 2014 W3C. All rights reserved.
//

#import "CSQRGenerator.h"
#import "QREncoder.h"


@implementation CSQRGenerator


+ (UIImage *) imageWithString:(NSString *)string
{
    DataMatrix * matrix = [QREncoder encodeWithECLevel:1 version:1 string:string];
    UIImage * image = [QREncoder renderDataMatrix:matrix imageDimension:280];
    return image;
}


@end
