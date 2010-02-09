//
//  SGGeoJSONNSArray.m
//  SGClient
//
//  Created by Derek Smith on 2/1/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "GeoJSON+NSArray.h"

@implementation NSArray (SGGeoJSONObject)

- (double) x
{
    if([self count] > 1)
        return [[self objectAtIndex:0] doubleValue];
    else
        return 0.0;
}

- (double) y
{
    if([self count] > 1)
        return [[self objectAtIndex:1] doubleValue];
    else
        return 0.0;
}

- (double) latitude
{
    return [self y];
}

- (double) longitude
{
    return [self x];
}

@end

@implementation NSMutableArray (GeoJSONObject)

- (void) setX:(double)x
{
    if([self count] > 1)
        [self replaceObjectAtIndex:0 withObject:[NSNumber numberWithDouble:x]];
}

- (void) setY:(double)y
{
    if([self count] > 1)
        [self replaceObjectAtIndex:1 withObject:[NSNumber numberWithDouble:y]];
}

- (void) setLatitude:(double)latitude
{
    [self setY:latitude];
}

- (void) setLongitude:(double)longitude
{
    [self setX:longitude];
}

@end

