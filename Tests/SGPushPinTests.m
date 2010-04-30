//
//  SGPushPinTests.m
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
#import "SGLocationService.h"

@interface SGPushPinTests : SGLocationServiceTests {
    
}

- (void) assertValidPushPinPolygon:(NSDictionary*)feature;

@end


@implementation SGPushPinTests

- (void) testContains
{
    CLLocationCoordinate2D coords = {40.017294990861913, -105.27759999949176};
    NSString* responseId = [self.locatorService  contains:coords];
    
    [self.requestIds setObject:[self expectedResponse:YES message:@"Should return a collection of polygons."]
                        forKey:responseId];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    STAssertTrue([recentReturnObject isFeatureCollection], @"Return object should be a collection of features");
    
    NSArray* features = [recentReturnObject objectForKey:@"features"];
    int size = [features count];
    STAssertTrue(size == 9, @"Nine polygons should be returned but was %i", size);
    for(NSDictionary* feature in features)
        [self assertValidPushPinPolygon:feature];    
}

- (void) testBoundary
{
    NSArray* boundaries = [NSArray arrayWithObjects:
                           [NSArray arrayWithObjects:@"Country:AF:tqnbw2", @"Afghanistan", @"0", @"1", @"291", nil],
                           [NSArray arrayWithObjects:@"Country:GB:gcw4ye", @"United Kingdom", @"1", @"1", @"26", nil],
                           [NSArray arrayWithObjects:@"Country:US:9z18bh", @"United States", @"1", @"1", @"70", nil],
                           [NSArray arrayWithObjects:@"Country:VU:rtq9kf", @"Vanuatu", @"1", @"1", @"11", nil],
                           nil];
    
    NSString* responseId = nil;
    for(NSArray* boundary in boundaries) {
     
        NSString* featureId = [boundary objectAtIndex:0];
        NSString* name = [boundary objectAtIndex:1];
//        NSString* rings = [boundary objectAtIndex:2];
//        NSString* vertices = [boundary objectAtIndex:3];
        
        responseId = [self.locatorService boundary:featureId];
        [self.requestIds setObject:[self expectedResponse:YES message:@"Must return a feature"] forKey:responseId];
        [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
         
        STAssertTrue([recentReturnObject isFeature], @"Return object should be a feature.");
        
        NSDictionary* properties = [recentReturnObject properties];
        STAssertTrue([[properties objectForKey:@"id"] isEqualToString:featureId], @"Feature ids should match up.");
        STAssertTrue([[properties objectForKey:@"name"] isEqualToString:name], @"Names should match up.");
    }
}

- (void) testOverlaps
{
    NSArray* fixtures = [NSArray arrayWithObjects:
                         [NSArray arrayWithObjects:@"40,-90,50,-80", [NSArray arrayWithObjects:@"CA", @"US", nil], nil],
                         [NSArray arrayWithObjects:@"51,-1,52,0", [NSArray arrayWithObjects:@"GB", nil], nil],
                         [NSArray arrayWithObjects:@"40,-90,50,-80", [NSArray arrayWithObjects:@"CA", nil], nil],
                         nil];
    
    NSString* responseId = nil;
    for(NSArray* fixture in fixtures) {
        
        NSArray* bounds = [[fixture objectAtIndex:0] componentsSeparatedByString:@","];
        NSArray* abbrs = [fixture objectAtIndex:1];
        
        SGEnvelope envelope = SGEnvelopeMake([[bounds objectAtIndex:0] doubleValue],
                                             [[bounds objectAtIndex:1] doubleValue], 
                                             [[bounds objectAtIndex:2] doubleValue],
                                             [[bounds objectAtIndex:3] doubleValue]);
        
        responseId = [self.locatorService overlapsType:nil inPolygon:envelope withLimit:[abbrs count]];
        [self.requestIds setObject:[self expectedResponse:YES message:@"Must return a feature collections."] forKey:responseId];
        [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
        STAssertTrue([recentReturnObject isFeatureCollection], @"Return object should be a feature collection");
        STAssertTrue([[recentReturnObject features] count] == [abbrs count], @"Unexpected length of features.");
    }
                         
}

- (void) assertValidPushPinPolygon:(NSDictionary*)feature
{
    STAssertTrue([[[feature geometry] type] isEqualToString:@"Polygon"], @"Geometry type should be Polygon");
}

@end
