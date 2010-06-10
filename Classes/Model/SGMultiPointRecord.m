//
//  SGMultiPointRecord.m
//  SGClient
//
//  Created by Derek Smith on 6/9/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGMultiPointRecord.h"

@implementation SGMultiPointRecord

- (CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D coord = {latitude, longitude};
    return coord;
}

- (MKMapRect) boundingMapRect
{
    CLLocationCoordinate2D center = [self coordinate];
    return MKMapRectMake(center.latitude, center.longitude, 0.0, 0.0);
}

@end
