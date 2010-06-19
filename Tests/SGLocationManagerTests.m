//
//  SGLocationManagerTests.m
//  SGClient
//
//  Created by Derek Smith on 6/17/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "SGLocationManager.h"
#import "SGLocationService.h"

@interface SGLocationManagerTests : SenTestCase <SGLocationManagerDelegate>
{
    @private
    SGLocationManager* locationManager;
    NSArray* stage;
}

@end

@implementation SGLocationManagerTests

- (void) setUp
{
    locationManager = [[SGLocationManager alloc] init];
    locationManager.delegate = self;
    stage = nil;
}

- (void) testRegionMovement
{
    SGLocationService* locationService = [SGLocationService sharedLocationService];
    NSMutableArray* stages = [NSMutableArray array];
    
    CLLocation* location = nil;
    NSArray* regions = nil;
    for(NSArray* stage in stages) {
        location = [self getLocationForStage:stage];
        regions = [self getRegionsForStage:stage];
        [locationManager locationManager:locationManager didUpdateToLocation:location fromLocation:nil];
        [locationService.operationQueue waitUntilAllOperationsAreFinished];
    }

}

- (NSArray*) stageForLocation:(CLLocation*)location regions:(NSArray*)regions
{
    return [NSArray arrayWithObjects:location, regions, nil];
}

- (CLLocation*) getLocationForStage:(NSArray*)stage
{
    return [stage objectAtIndex:0];
}

- (NSArray*) getRegionsForStage:(NSArray*)stage
{
    return [stage objectAtIndex:1];
}

- (NSArray*) getRegionDifference:(NSArray*)region
{
    return [region objectAtIndex:0];
}

- (NSArray*) getTotalRegions:(NSArray*)region
{
    return [region objectAtIndex:1];
}

- (void) setStage:(NSArray*)newStage
{
    
}

#pragma mark -
#pragma mark SGLocationManager delegate methods 

- (void) locationManager:(SGLocationManager*)locationManager didEnterRegions:(NSArray*)regions
{
    
}

- (void) locationManager:(SGLocationManager*)locationManager didLeaveRegions:(NSArray*)regions
{
    
}


@end
