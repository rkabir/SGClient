//
//  NSStringAdditions.m
//  SGLocatorServices
//
//  Created by Derek Smith on 7/5/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (SimpleGeo)

- (NSString*) URLEncodedString 
{

    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           NULL,
                                                                           CFSTR("!*'();:@&=+$,/?#[]"),
                                                                           kCFStringEncodingUTF8);
    return result;
}

- (NSString*) MinimalURLEncodedString {
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           CFSTR("%"),             
                                                                           CFSTR("?=&+"),          
                                                                           kCFStringEncodingUTF8); 
    [result autorelease];
    return result;
}

- (NSString*) URLDecodedString
{
    NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                           (CFStringRef)self,
                                                                                           CFSTR(""),
                                                                                           kCFStringEncodingUTF8);
    [result autorelease];
    return result;  
}

@end
