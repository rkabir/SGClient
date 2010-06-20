//
//  SGLocationManager.h
//  SGClient
//
//  Created by Derek Smith on 6/13/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SGLocationService.h"

/*!
* @class SGLocationManager 
* @abstract A wrapper around the CLLocationManager that provides notifications when
* a new location has entered and left a region that is defined by the SimpleGeo PushPin
* service.
*/
@interface SGLocationManager : CLLocationManager <CLLocationManagerDelegate, SGLocationServiceDelegate> {

    NSArray* regions;

    @private
    BOOL conformsToSGDelegate;
    NSString* regionResponseId;
}

/*!
* @property
* @abstract The current array of regions that the device's location
* resides in.
*/
@property (nonatomic, readonly) NSArray* regions;

@end

/*!
* @protocol SGLocationManagerDelegate
* @abstract ￼
* @discussion 
*/
@protocol SGLocationManagerDelegate <CLLocationManagerDelegate>

/*!
* @method locationManager:didEnterRegions:
* @abstract ￼
* @discussion ￼
* @param locationManager ￼
* @param regions ￼
*/
- (void) locationManager:(SGLocationManager*)locationManager didEnterRegions:(NSArray*)regions;

/*!
* @method locationManager:didLeaveRegions:
* @abstract ￼
* @discussion ￼
* @param locationManager ￼
* @param regions ￼
*/
- (void) locationManager:(SGLocationManager*)locationManager didLeaveRegions:(NSArray*)regions;

@end

