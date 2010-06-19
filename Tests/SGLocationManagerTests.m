//
//  SGLocationManagerTests.m
//  SGClient
//
//  Copyright (c) 2009-2010, SimpleGeo
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer. Redistributions 
//  in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  
//  Neither the name of the SimpleGeo nor the names of its contributors may
//  be used to endorse or promote products derived from this software 
//  without specific prior written permission.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Created by Derek Smith.
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
