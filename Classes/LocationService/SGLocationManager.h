//
//  SGLocationManager.h
//  SGClient
//
//  Created by Derek Smith on 6/13/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface SGLocationManager : CLLocationManager {

    NSArray* regions;

    @private
    BOOL conformsToSGDelegate;
    NSString* regionResponseId;
}

@property (nonatomic, readonly) NSArray* regions;

@end

@protocol SGLocationManagerDelegate <CLLocationManagerDelegate>

- (void) locationManager:(SGLocationManager*)locationManager didEnterRegions:(NSArray*)regions;
- (void) locationManager:(SGLocationManager*)locationManager didLeaveRegions:(NSArray*)regions;

@end

