//
//  SGLocationManager.h
//  SGClient
//
//  Created by Derek Smith on 6/13/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

/*!
* @class SGLocationManager 
* @abstract ￼ 
* @discussion 
*/
@interface SGLocationManager : CLLocationManager {

    NSArray* regions;

    @private
    BOOL conformsToSGDelegate;
    NSString* regionResponseId;
}

/*!
* @property
* @abstract
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

