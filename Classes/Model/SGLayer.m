//
//  SGLayer.m
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

#import "SGLayer.h"

#import "SGGeoJSONEncoder.h"

#import "SGRecordAnnotation.h"
#import "SGRecord.h"

@interface SGLayer (Private)

- (NSString*) getNextResponseId;

- (void) updateRecords:(NSDictionary*)requestObject;
- (void) retrieveRecords:(NSDictionary*)requestObject;

@end

@implementation SGLayer
@synthesize layerId, recentNearbyQuery, storeRetrievedRecords;

- (id) initWithLayerName:(NSString*)newLayer
{
    if(self = [super init]) {
        recentNearbyQuery = nil;
        layerResponseIds = [[NSMutableArray alloc] init];
        layerId = [newLayer retain];
        sgRecords = [[NSMutableDictionary alloc] init];
        storeRetrievedRecords = NO;
    } 
    
    return self;
}

#pragma mark -
#pragma mark Accessor methods 

- (SGRecord*) recordAnnotationFromGeoJSONObject:(NSDictionary*)dictionary
{   
    // Standard.
    SGRecord* record = [[[SGRecord alloc] init] autorelease];
    [record updateRecordWithGeoJSONObject:dictionary];

    return record;
}

#pragma mark -
#pragma mark Register Record with Layer 

- (NSArray*) recordAnnotations
{
    return [sgRecords allValues];
}

- (void) removeAllRecordAnnotations
{
    [sgRecords removeAllObjects];
}

- (void) addRecordAnnotation:(id<SGRecordAnnotation>)record
{
    if(record) {
        if([record respondsToSelector:@selector(setLayer:)])
           [record setLayer:layerId];
        else
            SGLog(@"SGLayer - Error, cannot change layer for record %@ because the selector is not defined.", record);
           
        [sgRecords setObject:record forKey:record.recordId];
    }
}

- (void) addRecordAnnotations:(NSArray*)records
{
    if(records && [records count]) 
        for(id<SGRecordAnnotation> record in records)
            [self addRecordAnnotation:record];
}

- (void) removeRecordAnnotations:(NSArray*)array
{
    for(id<SGRecordAnnotation> recordAnnotation in array)
        [self removeRecordAnnotation:recordAnnotation];
}

- (void) removeRecordAnnotation:(id<SGRecordAnnotation>)recordAnnotation
{
    [sgRecords removeObjectForKey:recordAnnotation.recordId];
}

- (NSInteger) recordAnnotationCount
{
    return [sgRecords count];
}

#pragma mark -
#pragma mark SGLayer update/retrieve methodsHer
 
- (NSString*) updateAllRecords
{
    return [self updateRecordAnnotations:[self recordAnnotations]];
}

- (NSString*) retrieveAllRecords
{
    return [self retrieveRecordAnnotations:[self recordAnnotations]];
}

- (NSString*) updateRecordAnnotations:(NSArray*)recordAnnotations
{    
    NSString* responseId = [[SGLocationService sharedLocationService] updateRecordAnnotations:recordAnnotations];
    if(responseId)
        [layerResponseIds addObject:responseId];
    
    return responseId;
}

- (NSString*) retrieveRecordAnnotations:(NSArray*)recordAnnoations
{
    NSString* responseId = [[SGLocationService sharedLocationService] retrieveRecordAnnotations:recordAnnoations];
    if(responseId)
        [layerResponseIds addObject:responseId];
    
    return responseId;
}

- (NSString*) nearby:(SGNearbyQuery*)query
{
    [[SGLocationService sharedLocationService] addDelegate:self];
    
    query.layer = layerId;
    NSString* responseId = [[SGLocationService sharedLocationService] nearby:query];
    if(responseId) {
        [layerResponseIds addObject:responseId];
        self.recentNearbyQuery = query;
    }
    
    return responseId;
}

- (NSString*) nextNearby
{
    NSString* requestId = nil;
    if(recentNearbyQuery && recentNearbyQuery.cursor)
        requestId = [self nearby:recentNearbyQuery];
    
    return requestId;
}

#pragma mark -
#pragma mark SGLocationService delegate methods  

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    [layerResponseIds removeObject:requestId];
}

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{   
    if([layerResponseIds containsObject:requestId]) {
        NSDictionary* geoJSONObject = (NSDictionary*)responseObject;        
        // Check to see if request matches our nearby query.
        // If it does, then we can append the cursor and get
        // ready for a possible pagination.
        if(recentNearbyQuery && recentNearbyQuery.requestId && [recentNearbyQuery.requestId isEqualToString:requestId])
            recentNearbyQuery.cursor = [geoJSONObject objectForKey:@"next_cursor"];
        
        if(storeRetrievedRecords) {
            NSArray* features = nil;
            if([geoJSONObject isFeature])
                features = [NSArray arrayWithObject:geoJSONObject];
            else 
                features = [geoJSONObject features];
            
            for(NSDictionary* feature in features)
                [self addRecordAnnotation:[self recordAnnotationFromGeoJSONObject:feature]];
        }
        
        [layerResponseIds removeObject:requestId];
    }
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<SGLayer %@, count: %i>", self.layerId, [sgRecords count]];
}

- (void) dealloc
{
    [sgRecords release];
    [layerId release];
    [[SGLocationService sharedLocationService] removeDelegate:self];
    [layerResponseIds release];
    
    if(recentNearbyQuery)
        [recentNearbyQuery release];
    
    [super dealloc];
}

@end
