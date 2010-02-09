//
//  NSArrayAdditions.m
//  SGClient
//
//  Created by Derek Smith on 1/19/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "NSArrayAdditions.h"


@implementation NSArray (SimpleGeo)

+ (BOOL) isValidNonEmptyArray:(NSArray*)array
{
    return array || (array && [array count]);
}

@end
