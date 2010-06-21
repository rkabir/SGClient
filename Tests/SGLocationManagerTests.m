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

#import "SGLocationServiceTests.h"
#import "SGLocationManager.h"
#import "NSDictionary_JSONExtensions.h"

@interface SGLocationManagerTests : SGLocationServiceTests <SGLocationManagerDelegate>
{
    @private
    NSMutableDictionary* expectedRegionChange;
}

- (void) setExpectedRegionsToLeave:(NSArray*)regions;
- (void) setExpectedRegionsToEnter:(NSArray*)regions;
- (NSArray*) getExpectedRegionsToLeave;
- (NSArray*) getExpectedRegionsToEnter;
- (void) clearExpectedRegionsToLeave;
- (void) clearExpectedRegionsToEnter;
- (NSArray*) stageForLocation:(CLLocation*)location regions:(NSArray*)regions;
- (CLLocation*) getLocationForStage:(NSDictionary*)newStage;
- (NSArray*) getRegionsForStage:(NSDictionary*)newStage;
- (NSArray*) getRegionDifferenceFrom:(NSArray*)regionsOne to:(NSArray*)regionsTwo;
- (BOOL) isRegionSetEqual:(NSArray*)regionsOne to:(NSArray*)regionsTwo;
- (NSArray*) getData;

@end

@implementation SGLocationManagerTests

- (void) setUp
{
    [super setUp];
    expectedRegionChange = [[NSMutableDictionary alloc] init];
}

- (void) testRegionMovement
{
    SGLocationManager* locationManager = [[SGLocationManager alloc] init];
    locationManager.delegate = self;
    
    NSArray* stages = [self getData];
    
    CLLocation* location = nil;
    NSArray* regions = nil;
    for(NSDictionary* stage in stages) {
        [self clearExpectedRegionsToEnter];
        [self clearExpectedRegionsToLeave];

        location = [self getLocationForStage:stage];
        regions = [self getRegionsForStage:stage];
        
        if(locationManager.regions) {
            NSArray* entering = [self getRegionDifferenceFrom:regions to:locationManager.regions];
            NSArray* leaving = [self getRegionDifferenceFrom:locationManager.regions to:regions];
            [self setExpectedRegionsToEnter:entering];
            [self setExpectedRegionsToLeave:leaving];
        } else
            [self setExpectedRegionsToEnter:regions];
        
        [locationManager locationManager:locationManager didUpdateToLocation:location fromLocation:nil];
        [self.locationService.operationQueue waitUntilAllOperationsAreFinished];        
        
        STAssertNil([self getExpectedRegionsToEnter], @"The delegate should have dealt with the callback.");
        STAssertNil([self getExpectedRegionsToLeave], @"The delegate should have dealt with the callback.");        
        STAssertTrue([self isRegionSetEqual:locationManager.regions to:regions], @"Region set should be equal.");
    }
}

- (void) setExpectedRegionsToLeave:(NSArray*)regions
{
    if(regions && [regions count])
        [expectedRegionChange setObject:regions forKey:@"leave"];
}

- (void) setExpectedRegionsToEnter:(NSArray*)regions
{
    if(regions && [regions count])
        [expectedRegionChange setObject:regions forKey:@"enter"];
}

- (NSArray*) getExpectedRegionsToLeave
{
    return [expectedRegionChange objectForKey:@"leave"];
}

- (NSArray*) getExpectedRegionsToEnter
{
    return [expectedRegionChange objectForKey:@"enter"];
}

- (void) clearExpectedRegionsToLeave
{
    [expectedRegionChange removeObjectForKey:@"leave"];
}

- (void) clearExpectedRegionsToEnter
{
    [expectedRegionChange removeObjectForKey:@"enter"];
}

- (NSArray*) stageForLocation:(CLLocation*)location regions:(NSArray*)regions
{
    return [NSArray arrayWithObjects:location, regions, nil];
}

- (CLLocation*) getLocationForStage:(NSDictionary*)newStage
{
    NSArray* coords = [newStage objectForKey:@"coordinates"];
    double lat = [[coords objectAtIndex:1] doubleValue];
    double lon = [[coords objectAtIndex:0] doubleValue];
    return [[[CLLocation alloc] initWithLatitude:lat longitude:lon] autorelease];
}

- (NSArray*) getRegionsForStage:(NSDictionary*)newStage
{
    return [newStage objectForKey:@"regions"];
}

- (NSArray*) getRegionDifferenceFrom:(NSArray*)regionsOne to:(NSArray*)regionsTwo
{
    NSMutableArray* difference = [NSMutableArray array];
    BOOL found = NO;
    for(NSDictionary* regionOne in regionsOne) {
        found = NO;
        NSString* regionOneId = [regionOne objectForKey:@"id"];
        for(NSDictionary* regionTwo in regionsTwo) {
            if([regionOneId isEqualToString:[regionTwo objectForKey:@"id"]]) {
                found = YES;
                break;
            }
        }
        
        if(!found)
            [difference addObject:regionOne];
    }

    return difference;
}

- (NSArray*) flattenRegions:(NSArray*)regionOne and:(NSArray*)regionTwo
{
    NSMutableDictionary* flattenRegion = [NSMutableDictionary dictionary];
    NSMutableArray* regions = [NSMutableArray arrayWithArray:regionOne];
    [regions addObjectsFromArray:regionTwo];
    for(NSDictionary* region in regions)
        [flattenRegion setObject:region forKey:[region objectForKey:@"id"]];
    
    return [flattenRegion allValues];
}

- (BOOL) isRegionSetEqual:(NSArray*)regionsOne to:(NSArray*)regionsTwo
{
    BOOL equal = ![[self getRegionDifferenceFrom:regionsOne to:regionsTwo] count];
    equal &= ![[self getRegionDifferenceFrom:regionsTwo to:regionsOne] count];
    return equal;
}

- (NSArray*) getData
{
    NSArray* points = [NSArray arrayWithObjects:@"-118.388672,34.052659]",
                                                @"-118.388672,34.052659",
                                                @"-118.38672,34.082522",
                                                @"-105.292969,39.96028", 
                                                nil];
    NSMutableArray* regionData = [NSMutableArray array];
    for(NSString* point in points) {
        NSArray* components = [point componentsSeparatedByString:@","];
        NSMutableDictionary* json = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     components, @"coordinates", nil];
        CLLocation* location = [[CLLocation alloc] initWithLatitude:[[components objectAtIndex:1] doubleValue]
                                                          longitude:[[components objectAtIndex:0] doubleValue]];
        NSString* responseId = [self.locationService contains:location.coordinate];
        [self.requestIds setObject:[self expectedResponse:YES message:@"Should return a collection of polygons."]
                            forKey:responseId];
        [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
        STAssertNotNil(recentReturnObject, @"PushPin should return regions for %@.", point);
        if(recentReturnObject)
            [json setObject:recentReturnObject forKey:@"regions"];
        [location release];
        [regionData addObject:json];
    }
    
    return regionData;
}

#pragma mark -
#pragma mark SGLocationManager delegate methods 

- (void) locationManager:(SGLocationManager*)locationManager didEnterRegions:(NSArray*)regions
{    NSArray* expectedRegions = [self getExpectedRegionsToEnter];
    STAssertTrue([self isRegionSetEqual:expectedRegions to:regions], @"Region set should be equal.");    
    [self clearExpectedRegionsToEnter];
}

- (void) locationManager:(SGLocationManager*)locationManager didLeaveRegions:(NSArray*)regions
{
    NSArray* expectedRegions = [self getExpectedRegionsToLeave];
    STAssertTrue([self isRegionSetEqual:expectedRegions to:regions], @"Region set should be equal.");
    [self clearExpectedRegionsToLeave];

}

@end
