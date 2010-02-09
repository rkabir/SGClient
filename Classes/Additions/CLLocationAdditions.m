//
//  CLLocationAdditions.m
//  SGLocatorServices
//
//  Created by Derek Smith on 7/4/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "CLLocationAdditions.h"

@implementation CLLocation (SGLocatorService)

- (BOOL) isEqualToLocation:(CLLocation*)location
{
    BOOL locationsAreEqual = YES;
    
    if(location) {

        // We are just going to compare these two values for now
        locationsAreEqual &= location.coordinate.latitude == self.coordinate.latitude;
        locationsAreEqual &= location.coordinate.longitude == self.coordinate.longitude;
    }
    
    return locationsAreEqual;
}

- (double) getBearingFromCoordinate:(CLLocationCoordinate2D)coord;
{
    CLLocationCoordinate2D first = self.coordinate;
    CLLocationCoordinate2D second = coord;
    
    double deltaLong = first.longitude - second.longitude;
    
    //    θ =	atan2(	sin(Δlong).cos(lat2),
    //              cos(lat1).sin(lat2) − sin(lat1).cos(lat2).cos(Δlong) )    
    
    double b = atan2(sin(deltaLong) * cos(second.latitude), cos(first.latitude) * sin(second.latitude) - sin(first.latitude) * cos(second.latitude) * cos(deltaLong)); 
    return (b * 180.0 / M_PI);
}

@end
