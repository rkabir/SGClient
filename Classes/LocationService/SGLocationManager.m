//
//  SGLocationManager.m
//  SGClient
//
//  Created by Derek Smith on 6/13/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLocationManager.h"

@interface SGLocationManager (Private)

- (BOOL) validResponseId:(NSString*)responseId;
- (void) updateRegions:(NSArray*)newRegion;

- (BOOL) isRegion:(NSDictionary*)regionOne equalToRegion:(NSDictionary*)regionTwo;
- (BOOL) isRegion:(NSDictionary*)region foundInSet:(NSArray*)regionSet;

@end

@implementation SGLocationManager
@synthesize regions;

- (id) init
{
    if(self = [super init]) {
        regions = nil;
        regionResponseId = nil;
        trueDelegate = nil;
        [super setDelegate:self];
    }
    
    return self;
}

- (void) setDelegate:(id<SGLocationManagerDelegate>)newDelegate
{
    trueDelegate = newDelegate;
    if([newDelegate conformsToProtocol:@protocol(SGLocationManagerDelegate)])
        [[SGLocationService sharedLocationService] addDelegate:self];
}

#pragma mark -
#pragma mark CLLocationManager delegate methods 

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
    if(!regionResponseId)
        regionResponseId = [[[SGLocationService sharedLocationService] contains:newLocation.coordinate] retain];
    
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
        [trueDelegate locationManager:self didUpdateToLocation:newLocation fromLocation:oldLocation];
}

- (void) locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:didFailWithError:)])
        [trueDelegate locationManager:self didFailWithError:error];
}

- (void) locationManager:(CLLocationManager*)manager didUpdateHeading:(CLHeading*)newHeading
{
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)])
        [trueDelegate locationManager:self didUpdateHeading:newHeading];    
}

#if __IPHONE_4_0 && __IPHONE_4_0 && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0  

- (BOOL) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)manager
{
    BOOL value = NO;
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)])
        value = [trueDelegate locationManagerShouldDisplayHeadingCalibration:self];
    
    return value;
}

- (void) locationManager:(CLLocationManager *)managerdidEnterRegion:(CLRegion*)region
{
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
        [trueDelegate locationManager:self didEnterRegion:region];
}

- (void) locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:didExitRegion:)])
        [trueDelegate locationManager:self didExitRegion:region];
}

- (void) locationManager:(CLLocationManager*)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if(trueDelegate && [trueDelegate respondsToSelector:@selector(locationManager:monitoringDidFailForRegion:withError:)])
        [trueDelegate locationManager:self monitoringDidFailForRegion:region withError:error];
}

#endif

#pragma mark -
#pragma mark SGLocationService delegate methods 

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{
    if([self validResponseId:requestId]) {
        [self updateRegions:(NSArray*)responseObject];
        [regionResponseId release];
        regionResponseId = nil;
    }    
}

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{    
    if([self validResponseId:requestId]) {
        SGLog(@"SGLocationManager - Unable to retrieve region (%@)", [error description]);     
        [regionResponseId release];
        regionResponseId = nil;
    }
}

#pragma mark -
#pragma mark Utility methods 

- (BOOL) validResponseId:(NSString*)responseId
{
    return regionResponseId && [regionResponseId isEqualToString:responseId];
}

- (void) updateRegions:(NSArray*)newRegions
{
    NSMutableArray* addedRegions = [NSMutableArray array];
    NSMutableArray* removedRegions = [NSMutableArray array];
    if(!regions) {
        regions = [newRegions retain];
        [addedRegions addObjectsFromArray:regions];
    } else {
        for(NSDictionary* region in regions)
            if(![self isRegion:region foundInSet:newRegions])
                [removedRegions addObject:region];
        
        for(NSDictionary* region in newRegions)
            if(![self isRegion:region foundInSet:regions])
                [addedRegions addObject:region];
                
        [regions release];
        regions = [newRegions retain];
    }

    if([addedRegions count])
        [trueDelegate locationManager:self didEnterRegions:addedRegions];
    
    if([removedRegions count])
        [trueDelegate locationManager:self didLeaveRegions:removedRegions];
}

- (BOOL) isRegion:(NSDictionary*)newRegion foundInSet:(NSArray*)regionSet
{
    for(NSDictionary* region in regionSet)
        if([self isRegion:newRegion equalToRegion:region])
            return YES;
        
    return NO;
}

- (BOOL) isRegion:(NSDictionary*)regionOne equalToRegion:(NSDictionary*)regionTwo
{
    return [[regionOne objectForKey:@"id"] isEqualToString:[regionTwo objectForKey:@"id"]];
}
          
- (void) dealloc
{
    [[SGLocationService sharedLocationService] removeDelegate:self];
    [regionResponseId release];
    [regions release];
    [super dealloc];
}

@end
