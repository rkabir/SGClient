//
//  SGLayer.m
//  CCLocatorServices
//
//  Created by Derek Smith on 9/15/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLayer.h"

#import "SGGeoJSONEncoder.h"

#import "SGRecordAnnotation.h"
#import "SGRecord.h"

@interface SGLayer (Private)

- (NSString*) getNextResponseId;

- (void) updateRecords:(NSDictionary *)requestObject;
- (void) retrieveRecords:(NSDictionary *)requestObject;

@end


@implementation SGLayer

@synthesize layerId;

- (id) initWithLayerName:(NSString*)newLayer
{
    if(self = [super init]) {
        
        if(!newLayer) {
         
            NSBundle* bundle = [NSBundle mainBundle];
            newLayer = [bundle bundleIdentifier];
            
        }

        _layerResponseIds = [[NSMutableArray alloc] init];
        
        layerId = [newLayer retain];
        
        _sgRecords = [[NSMutableDictionary alloc] init];
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
    return [_sgRecords allValues];
}

- (void) removeAllRecordAnnotations
{
    [_sgRecords removeAllObjects];
}

- (void) addRecordAnnotation:(id<SGRecordAnnotation>)record
{
    if(record) {
        
        if([record respondsToSelector:@selector(setLayer:)])
           [record setLayer:layerId];
        else
            SGLog(@"SGLayer - Error, cannot change layer for record %@ because the selector is not defined.", record);
           
        [_sgRecords setObject:record forKey:record.recordId];
        
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
    [_sgRecords removeObjectForKey:recordAnnotation.recordId];
}

- (NSInteger) recordAnnotationCount
{
    return [_sgRecords count];
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
        [_layerResponseIds addObject:responseId];
    
    return responseId;
}

- (NSString*) retrieveRecordAnnotations:(NSArray*)recordAnnoations
{
    NSString* responseId = [[SGLocationService sharedLocationService] retrieveRecordAnnotations:recordAnnoations];
    if(responseId)
        [_layerResponseIds addObject:responseId];
    
    return responseId;
}

- (NSString*) retrieveRecordsForGeohash:(SGGeohash)region types:(NSArray*)types limit:(NSInteger)limit
{
    NSString* responseId = [[SGLocationService sharedLocationService] retrieveRecordsForGeohash:region
                                                                                       layers:[NSArray arrayWithObject:layerId]
                                                                                        types:types
                                                                                        limit:limit];
    if(responseId)
        [_layerResponseIds addObject:responseId];
    
    return responseId;
}

- (NSString*) retrieveRecordsForCoordinate:(CLLocationCoordinate2D)coord 
                                    radius:(double)radius
                                     types:(NSArray*)types
                                     limit:(NSInteger)limit
{
    NSString* responseId = [[SGLocationService sharedLocationService] retrieveRecordsForCoordinate:coord
                                                                                            radius:radius
                                                                                            layers:[NSArray arrayWithObject:layerId]
                                                                                             types:types
                                                                                             limit:limit];
    if(responseId)
        [_layerResponseIds addObject:responseId];
    
    return responseId;
}

#pragma mark -
#pragma mark SGLocationService delegate methods  

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    [_layerResponseIds removeObject:requestId];
}

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{   
    if([_layerResponseIds containsObject:requestId]) {

        NSDictionary* geoJSONObject = (NSDictionary*)responseObject;
        NSArray* features = [geoJSONObject features];
        
        if(features && [features count])
            SGLog(@"SGLayer - updating %i record(s) for %@", [features count], [self description]);
        else if(responseObject) 
            features = [NSArray arrayWithObject:geoJSONObject];
            
        NSString* recordId = nil;
        id<SGRecordAnnotation> annotation = nil;
        for(NSDictionary* feature in features) {
        
            recordId = [feature id];
            
            if(recordId) {
            
                annotation = [_sgRecords objectForKey:recordId];
                
                if(annotation) {
                
                    if([annotation respondsToSelector:@selector(updateRecordWithGeoJSONObject:)])
                        [annotation updateRecordWithGeoJSONObject:feature];
                
                } else {
             
                    annotation = [self recordAnnotationFromGeoJSONObject:feature];

                    if(annotation)
                        [_sgRecords setObject:annotation forKey:annotation.recordId];
                }
            
            }
        
        }
        
        [_layerResponseIds removeObject:requestId];
    }
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<SGLayer %@, count: %i>", self.layerId, [_sgRecords count]];
}

- (void) dealloc
{
    [_sgRecords release];
    [layerId release];
    [[SGLocationService sharedLocationService] removeDelegate:self];
    [_layerResponseIds release];
    
    [super dealloc];
}

@end
