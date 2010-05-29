//
//  SGLocationService.m
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

#import "SGLocationTypes.h"
#import "SGLocationService.h"

#import "SGOAuth.h"
#import "SGRecord.h"

#import "SGAdditions.h"
#import "SGCacheHandler.h"

#import "geohash.h"
#import "CJSONSerializer.h"
#import "NSDictionary_JSONExtensions.h"
#import "SGGeoJSONEncoder.h"
    
enum SGHTTPRequestParamater {
 
    kSGHTTPRequestParameter_Method = 0,
    kSGHTTPRequestParameter_File,
    kSGHTTPRequestParameter_Body,
    kSGHTTPRequestParameter_Params,
    kSGHTTPRequestParameter_ResponseId
    
};

typedef NSInteger SGHTTPRequestParamater;

static SGLocationService* sharedLocationService = nil;
static int requestIdNumber = 0;
static BOOL callbackOnMainThread = NO;

static id<SGAuthorization> dummyAuthorizer = nil;

static NSString* mainURL = @"http://api.simplegeo.com";
static NSString* apiVersion = @"0.1";

@interface SGLocationService (Private) <SGAuthorization, CLLocationManagerDelegate, SGLocationServiceDelegate>

- (NSString*) getNextResponseId;

- (void) pushInvocationWithArgs:(NSArray*)args;
- (void) pushMultiInvocationWithArgs:(NSArray *)args;

- (NSObject*) deleteRecord:(NSString*)recordId layer:(NSString*)layer push:(BOOL)push;
- (NSObject*) retrieveRecord:(NSString*)recordId layer:(NSString*)layer push:(BOOL)push;
- (NSObject*) updateRecord:(NSString*)recordId layer:(NSString*)layer coord:(CLLocationCoordinate2D)coord properties:(NSDictionary*)properties push:(BOOL)push;

- (NSArray*) allTypes;

- (void) succeeded:(NSDictionary*)responseDictionary;
- (void) failed:(NSDictionary*)responseDictionary;

- (NSDictionary*) sendHTTPRequest:(NSString*)requestType 
                            toURL:(NSString*)file 
                             body:(NSData*)body
                       withParams:(NSDictionary*)params 
                        requestId:(NSString*)requestId
                         callback:(NSNumber*)callback;

- (void) sendMultipleHTTPRequest:(NSArray*)requestList
                       requestId:(NSString*)requestId;

#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED

- (void) initializeCommitLog;
- (void) replayCommitLog;
- (void) updateBackgroundRecords:(NSArray*)backgroundRecords;

#endif

@end

@implementation SGLocationService
@synthesize operationQueue;
@dynamic HTTPAuthorizer;

#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED

@synthesize useGPS, useWiFiTowers;

#endif

- (id) init
{
    if(self = [super init]) {
        operationQueue = [[NSOperationQueue alloc] init];
        
        delegates = [[NSMutableArray alloc] init];
        
        if(!dummyAuthorizer)
            dummyAuthorizer = [[SGOAuth alloc] initWithKey:@"key" secret:@"secret"];
        
        [self setHTTPAuthorizer:dummyAuthorizer];
        
#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED
        
        commitLog = nil;
        cachedResponseIds = [[NSMutableArray alloc] init];
      
        useGPS = NO;
        useWiFiTowers = YES;
#endif
        
        callbackOnMainThread = YES;
    }
    
    return self;
}

+ (SGLocationService*) sharedLocationService
{
    if(!sharedLocationService)
        sharedLocationService = [[[SGLocationService alloc] init] retain];
    
    return sharedLocationService;
}

+ (void) callbackOnMainThread:(BOOL)callback
{
    callbackOnMainThread = callback;
}

- (void) addDelegate:(id<SGLocationServiceDelegate>)delegate
{
    if([delegates indexOfObject:delegate] == NSNotFound &&
                    [delegate conformsToProtocol:@protocol(SGLocationServiceDelegate)])
        [delegates addObject:delegate];
}

- (void) removeDelegate:(id<SGLocationServiceDelegate>)delegate
{
    [delegates removeObject:delegate];
}

- (NSArray*) delegates
{
    return delegates;
}

- (id<SGAuthorization>) HTTPAuthorizer
{
    return HTTPAuthorizer;
}

- (void) setHTTPAuthorizer:(id<SGAuthorization>)authorizer
{
    if(authorizer && [authorizer conformsToProtocol:@protocol(SGAuthorization)]) {
        // Whenever the authorizer changes, the username can also change.
        // We need to save the current dictionary to the proper directory
        // and reload a new one.
        HTTPAuthorizer = authorizer;
        
#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED
        
        [self initializeCommitLog];   

#endif

    }
}

#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED

- (void) initializeCommitLog
{
    if(!commitLog) {
        SGLog(@"SGLocationService - Initializing the commit log");
        commitLog = [[SGCommitLog alloc] initWithName:@"SGLocationService"];
    }
}

- (void) replayCommitLog
{
    SGLog(@"SGLocationService - Replaying the commit log");
    if(!commitLog)
        [self initializeCommitLog];
    
    if(HTTPAuthorizer) {
        NSString* username = [HTTPAuthorizer username];
        NSString* key = @"update_records";
        NSDictionary* updateCommits = [[commitLog getCommitsForUsername:username key:key] retain];
        
        NSMutableArray* features = [NSMutableArray array];
        NSDictionary* feature = nil;
        NSError* error = nil;
        for(NSString* commitKey in updateCommits) {
            feature = [NSDictionary dictionaryWithJSONData:[updateCommits objectForKey:commitKey] error:&error];
            if(feature && !error)
                [features addObject:feature];
            error = nil;
        }
        
        // Create a proper GeoJSON object with the given features.
        NSDictionary* featureCollection = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"FeatureCollection", @"type",
                                           features, @"features",
                                           nil];
        [self updateBackgroundRecords:[SGGeoJSONEncoder recordsForGeoJSONObject:featureCollection]];
        
        // Remove the commits because they are no longer needed.
        [commitLog deleteUsername:username key:key];
        [updateCommits release];
    }
}

#pragma mark -
#pragma mark Background location methods

- (void) becameActive
{
    [self replayCommitLog];
}

- (void) enterBackground
{
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = [device respondsToSelector:@selector(isMultitaskingSupported)] && device.multitaskingSupported;
    if(backgroundSupported) {        
        SGLog(@"SGLocationService - Entering as a background process");
        // We also need to monitory ourself because
        // sockets loss is common in the background processes.
        [self initializeCommitLog];        
        [self addDelegate:self];
        
        // See if the NSOperationQueue has emptied out.
        // If it hasn't, then we ask for more time to deliver
        // the requests.
        if(self.operationQueue && [self.operationQueue operationCount]) {
            UIApplication* application = [UIApplication sharedApplication];
            self->backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self->backgroundTask != UIInvalidBackgroundTask) {
                        [application endBackgroundTask:self->backgroundTask];
                        self->backgroundTask = UIInvalidBackgroundTask;
                    }
                });
            }];            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                SGLog(@"SGLocationService - Waiting for NSOperationQueue to empty");
                if(self->backgroundTask != UIInvalidBackgroundTask) {
                    [self->operationQueue waitUntilAllOperationsAreFinished];                    
                    [application endBackgroundTask:self->backgroundTask];
                    self->backgroundTask = UIInvalidBackgroundTask;
                }
            });
        }
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;    
        
        if(useWiFiTowers)
            [locationManager startMonitoringSignificantLocationChanges];        
        
        if(useGPS)
            [locationManager startUpdatingLocation];
    }
}

- (void) leaveBackground
{
    if(locationManager) {
        [locationManager stopMonitoringSignificantLocationChanges];
        locationManager.delegate = nil;
        [locationManager release];
        locationManager = nil;
    }
    if(commitLog)
        [commitLog flush];

    [self removeDelegate:self];
}

- (void) updateBackgroundRecords:(NSArray*)backgroundRecords
{
    // We can only update records in sets of 100
    NSMutableArray* records = [NSMutableArray arrayWithArray:backgroundRecords];
    int amountOfRecords = [records count];
    NSString* responseId = nil;
    while(amountOfRecords) {
        if(amountOfRecords <= 100) {
            responseId = [self updateRecordAnnotations:records];
            [records removeAllObjects];
        } else {
            NSRange range;
            range.location = 0;
            range.length = 100;
            responseId = [self updateRecordAnnotations:[records subarrayWithRange:range]];
            range.length = amountOfRecords;
            records = [NSMutableArray arrayWithArray:[records subarrayWithRange:range]];
        }
        if(responseId)
            [cachedResponseIds addObject:responseId];
        amountOfRecords = [records count];
    }
    
    SGLog(@"SGLocationService - Updated %i records that were updated in the background", [backgroundRecords count]);
}

#pragma mark -
#pragma mark CLLocationManager delegate methods 

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)newLocation fromLocation:(CLLocation*)oldLocation
{
    /* 
     * The only time this object should be registered to recieve location updates
     * is when the surrounding application enters the background state. 
     */
    NSMutableArray* totalCachedRecords = [NSMutableArray array];
    NSMutableArray* totalUpdatedRecords = [NSMutableArray array];
    NSArray* records = nil;
    for(id<SGLocationServiceDelegate> delegate in delegates) {
        if([delegate respondsToSelector:@selector(locationService:recordsForBackgroundLocationUpdate:)]) {
            records = [delegate locationService:self recordsForBackgroundLocationUpdate:newLocation];
            if(records) {
                if([delegate respondsToSelector:@selector(locationService:shouldCacheRecord:)]) {
                    for(id<SGRecordAnnotation> record in records)
                        if([delegate locationService:self shouldCacheRecord:record])
                            [totalCachedRecords addObject:record];
                        else
                            [totalUpdatedRecords addObject:record];
                } else
                    [totalCachedRecords addObjectsFromArray:records];
            }
        }
    }
    
    if([totalCachedRecords count]) {
        NSDictionary* featureCollection = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotations:totalCachedRecords];
        NSData* featureCollectionData = [[[CJSONSerializer serializer] serializeObject:featureCollection] dataUsingEncoding:NSASCIIStringEncoding];
        if(commitLog && HTTPAuthorizer) {
            NSString* username = [HTTPAuthorizer username];
            [commitLog addCommit:featureCollectionData forUsername:username andKey:@"record_updates"];
        }
    }   

    [self updateBackgroundRecords:totalUpdatedRecords];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    SGLog(@"SGLocationService - %@", [error description]);
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SGLocationService delegate methods 
//////////////////////////////////////////////////////////////////////////////////////////////// 

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{
    if([cachedResponseIds containsObject:requestId]) {
        SGLog(@"SGLocationService - Cached request successfully sent");
        [cachedResponseIds removeObject:requestId];
    }
}

 - (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    if([cachedResponseIds containsObject:requestId]) {
        SGLog(@"SGLocationService - Cached request was unsuccessfully (%@)", [error description]);
        // We might want to recommit the bad request
        [cachedResponseIds removeObject:requestId];
    }
}

#endif

#pragma mark -
#pragma mark Record Information 

- (NSString*) deleteRecordAnnotation:(id<SGRecordAnnotation>)record
{
    return record ? [self deleteRecord:record.recordId layer:record.layer] : nil;
}

- (NSString*) deleteRecordAnnotations:(NSArray*)records
{
    NSMutableArray* requests = [NSMutableArray array];
    NSArray* request = nil;
    for(id<SGRecordAnnotation> recordAnnotation in records) {
        request = (NSArray*)[self deleteRecord:recordAnnotation.recordId
                                layer:recordAnnotation.layer
                                 push:NO];
        
        if(!request)
            return nil;
        else
            [requests addObject:request];
    }
    
    NSString* requestId = nil;
    if([requests count]) {
        requestId = [self getNextResponseId];
        [self pushMultiInvocationWithArgs:[NSArray arrayWithObjects:requests, requestId, nil]];
    }
    
    return requestId;    
}

- (NSString*) deleteRecord:(NSString*)recordId layer:(NSString*)layer
{
    return (NSString*)[self deleteRecord:recordId layer:layer push:YES];
}

- (NSObject*) deleteRecord:(NSString*)recordId layer:(NSString*)layer push:(BOOL)push
{
    NSString* requestId = nil;
    NSArray* params = nil;
    if(recordId && ![recordId isKindOfClass:[NSNull class]] &&
       layer && ![layer isKindOfClass:[NSNull class]]) {
        requestId = [self getNextResponseId];
        
        params = [NSArray arrayWithObjects:
                           @"DELETE",
                           [NSString stringWithFormat:@"/records/%@/%@.json", layer, recordId],
                           [NSNull null],
                           [NSNull null],
                           requestId,
                           nil];
        
        if(push)
            [self pushInvocationWithArgs:params];
    }
    
    return push ? requestId : (NSObject*)params;    
}

- (NSString*) retrieveRecordAnnotation:(id<SGRecordAnnotation>)record
{
    return record ? [self retrieveRecordAnnotations:[NSArray arrayWithObject:record]] : nil;
}

- (NSString*) retrieveRecordAnnotations:(NSArray*)records
{
    if(!records || (records && ![records count]))
       return nil;

    NSMutableArray* recordIds = [NSMutableArray array];
    for(id<SGRecordAnnotation> annotation in records)
        [recordIds addObject:[annotation recordId]];
    
    NSString* responseId = nil;
    if([recordIds count]) {
        
        responseId = [self getNextResponseId];
        
        NSString* layerId = [((id<SGRecordAnnotation>)[records lastObject]) layer];
     
        NSArray* params = [NSArray arrayWithObjects:
                           @"GET",
                           [NSString stringWithFormat:@"/records/%@/%@.json", layerId, [recordIds componentsJoinedByString:@","]],
                           [NSNull null],
                           [NSNull null],
                           responseId,
                           nil];
        
        [self pushInvocationWithArgs:params];
    }
    
    return responseId;    
}

- (NSString*) retrieveRecord:(NSString*)recordId layer:(NSString*)layer
{
    return (NSString*)[self retrieveRecord:recordId layer:layer push:YES];
}

- (NSObject*) retrieveRecord:(NSString*)recordId layer:(NSString*)layer push:(BOOL)push
{
    NSString* requestId = nil;
    NSArray* params = nil;
    if(recordId && ![recordId isKindOfClass:[NSNull class]] &&
       layer && ![layer isKindOfClass:[NSNull class]]) {
        
        requestId = [self getNextResponseId];
        
        params = [NSArray arrayWithObjects:
                           @"GET",
                           [@"/records" stringByAppendingFormat:@"/%@/%@.json", layer, recordId],
                           [NSNull null],
                            [NSNull null],
                           requestId,
                           nil];
        
        if(push)
            [self pushInvocationWithArgs:params];
        
    }
    
    return push ? requestId : (NSObject*)params;    
}

- (NSString*) updateRecordAnnotation:(id<SGRecordAnnotation>)record
{
    NSString* requestId = nil;

    if(record)
        requestId = [self updateRecordAnnotations:[NSArray arrayWithObject:record]];
    
    return requestId;
}

- (NSString*) updateRecordAnnotations:(NSArray*)records
{
    // Bail if we have nothing.
    if(!records || (records && ![records count]))
        return nil;
    
    NSDictionary* geoJSONDictionary = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotations:records];

    NSString* responseId = nil;
    if(geoJSONDictionary) {
     
        responseId = [self getNextResponseId];
        NSData* body = [[[CJSONSerializer serializer] serializeObject:geoJSONDictionary] dataUsingEncoding:NSASCIIStringEncoding];
        
        NSString* layer = [((id<SGRecordAnnotation>)[records lastObject]) layer];
        
        NSArray* params = [NSArray arrayWithObjects:
                                                  @"POST",
                                                  [@"/records/" stringByAppendingFormat:@"%@.json",  layer],
                                                  body,
                                                  [NSNull null],
                                                  responseId,
                                                  nil];
                                
        [self pushInvocationWithArgs:params];
    }
    
    return responseId;
}

- (NSString*) updateRecord:(NSString*)recordId layer:(NSString*)layer coord:(CLLocationCoordinate2D)coord properties:(NSDictionary*)properties
{
    return (NSString*)[self updateRecord:recordId layer:layer coord:coord properties:properties push:YES];   
}

- (NSObject*) updateRecord:(NSString*)recordId layer:(NSString*)layer coord:(CLLocationCoordinate2D)coord properties:(NSDictionary*)properties push:(BOOL)push       
{
    NSArray* params = nil;
    NSString* requestId = nil;
    if(recordId && ![recordId isKindOfClass:[NSNull class]] &&
       layer && ![layer isKindOfClass:[NSNull class]]) {
        
        requestId = [self getNextResponseId];
        
        SGRecord* record = [[SGRecord alloc] init];
        record.recordId = recordId;
        record.layer = layer;
        record.properties = [NSMutableDictionary dictionaryWithDictionary:properties];
        record.latitude = coord.latitude;
        record.longitude = coord.longitude;
        
        NSString* type = [properties objectForKey:@"type"];
        if(type)
            record.type = type;
        
        NSDictionary* geoJSONObject = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotation:record];
        
        NSData* body = [[[CJSONSerializer serializer] serializeObject:geoJSONObject] dataUsingEncoding:NSASCIIStringEncoding];
        
        params = [NSArray arrayWithObjects:
                           @"PUT",
                           [NSString stringWithFormat:@"/records/%@/%@.json", layer, recordId],
                           body,
                           [NSNull null],
                           requestId,
                           nil];
        [record release];
        
        if(push)
            [self pushInvocationWithArgs:params];
    }    
    
    return push ? requestId : (NSObject*)params;
}


- (NSString*) retrieveRecordAnnotationHistory:(id<SGRecordAnnotation>)record limit:(int)limit
{
    return [self retrieveRecordHistory:record.recordId layer:record.layer limit:limit];
}

- (NSString*) retrieveRecordHistory:(NSString*)recordId layer:(NSString*)layer limit:(int)limit
{
    NSString* requestId = nil;
    
    if(recordId && ![recordId isKindOfClass:[NSNull class]] &&
       layer && ![layer isKindOfClass:[NSNull class]]) {
        
        requestId = [self getNextResponseId];
        
        NSObject* limitParam = [NSNull null];
        if(limit > 0)
            limitParam = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];

        NSArray* params = [NSArray arrayWithObjects:
                           @"GET",
                           [NSString stringWithFormat:@"/records/%@/%@/history.json", layer, recordId],
                           [NSNull null],
                           limitParam,
                           requestId,
                           nil];

        [self pushInvocationWithArgs:params];
    }

    return requestId;
}

#pragma mark -
#pragma mark Layer

- (NSString*) layerInformation:(NSString*)layerName
{
    NSString* responseId = [self getNextResponseId];
    
    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/layer/%@.json", layerName],
                       [NSNull null],
                       [NSNull null],
                       responseId,
                       nil];
    
    [self pushInvocationWithArgs:params];
    
    return responseId;
}

#pragma mark -
#pragma mark Nearby

- (NSString*) nearby:(SGNearbyQuery*)query
{
    NSString* requestId = [self getNextResponseId];
    
    NSMutableArray* params = [NSArray arrayWithObjects:
                              @"GET",
                              [query uri],
                              [NSNull null],
                              [query params],
                              requestId,
                              nil];
    [self pushInvocationWithArgs:params];
    
    query.requestId = requestId;
    
    return requestId;
}

- (NSString*) reverseGeocode:(CLLocationCoordinate2D)coord
{
    NSString* responseId = [self getNextResponseId];
    
    
    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/nearby/address/%f,%f.json", coord.latitude, coord.longitude],
                       [NSNull null],
                       [NSNull null],
                       responseId,
                       nil];
    [self pushInvocationWithArgs:params];
    
    return responseId;
}

#pragma mark -
#pragma mark SpotRank

- (NSString*) densityForCoordinate:(CLLocationCoordinate2D)coord day:(NSString*)day hour:(int)hour
{
    if(hour < 0 || hour > 24)
        return [self densityForCoordinate:coord day:day];
    
    if(!day)
        day = kSpotRank_Monday;
    
    NSString* responseId = [self getNextResponseId];
    
    NSArray* params = [NSArray arrayWithObjects:
                            @"GET",
                            [NSString stringWithFormat:@"/density/%@/%i/%f,%f.json", day, hour, coord.latitude, coord.longitude],
                            [NSNull null],
                            [NSNull null],
                            responseId,
                       nil];
    
    [self pushInvocationWithArgs:params];
    
    return responseId;                   
}

- (NSString*) densityForCoordinate:(CLLocationCoordinate2D)coord day:(NSString*)day
{
    NSString* responseId = [self getNextResponseId];
    
    if(!day)
        day = kSpotRank_Monday;

    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/density/%@/%f,%f.json", day, coord.latitude, coord.longitude],
                       [NSNull null],
                       [NSNull null],
                       responseId,
                       nil];
    
    [self pushInvocationWithArgs:params];
    
    return responseId;                   
}

#pragma mark -
#pragma mark PushPin

- (NSString*) contains:(CLLocationCoordinate2D)coord;
{
    NSString* responseId = [self getNextResponseId];
    
    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/contains/%f,%f.json", coord.latitude, coord.longitude],
                       [NSNull null],
                       [NSNull null],
                       responseId,
                       nil];
    
    [self pushInvocationWithArgs:params];

    return responseId;                       
}

- (NSString*) boundary:(NSString*)featureId
{
    NSString* responseId = [self getNextResponseId];
    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/boundary/%@.json", featureId],
                       [NSNull null],
                       [NSNull null],
                       responseId,
                       nil];
    
    [self pushInvocationWithArgs:params];    
    
    return responseId;
}

- (NSString*) overlapsType:(NSString*)type inPolygon:(SGEnvelope)envelope withLimit:(int)limit
{
    NSString* responseId = [self getNextResponseId];
    NSString* envelopeString = SGEnvelopeGetString(envelope);
    
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    if(type)
        [dictionary setValue:type forKey:@"type"];

    if(limit > 0)
        [dictionary setValue:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];
    
    NSArray* params = [NSArray arrayWithObjects:
                       @"GET",
                       [NSString stringWithFormat:@"/overlaps/%@.json", envelopeString],
                       [NSNull null],
                       dictionary,
                       responseId,
                       nil];

    [self pushInvocationWithArgs:params];    
    
    return responseId;
}

#pragma mark -
#pragma mark HTTP Request methods 
 

- (void) succeeded:(NSDictionary*)responseDictionary
{
    NSString* requestId = [[responseDictionary objectForKey:@"requestId"] retain];
    NSObject* responseObject = [[responseDictionary objectForKey:@"responseObject"] retain];

    SGLog(@"SGLocationService - Request %@ succeeded with %i queued operations", requestId, [self.operationQueue.operations count]);
    
    for(id<SGLocationServiceDelegate> delegate in delegates)
        [delegate locationService:self succeededForResponseId:requestId responseObject:responseObject];
    
    [requestId release];
    [responseObject release];
}

- (void) failed:(NSDictionary*)responseDictionary
{
    NSString* requestId = [[responseDictionary objectForKey:@"requestId"] retain];
    NSError* error = [[responseDictionary objectForKey:@"error"] retain];
    
    SGLog(@"SGLocationService - Request failed: %@ Error: %@", requestId, [error description]);

    for(id<SGLocationServiceDelegate> delegate in delegates)
        [delegate locationService:self failedForResponseId:requestId error:error];
    
    [requestId release];
    [error release];
}

- (void) sendMultipleHTTPRequest:(NSArray*)requestList
                                requestId:(NSString*)requestId
{
    
    NSMutableArray* responses = [NSMutableArray array];
    NSArray* request = nil;
    NSDictionary* response = nil;
    for(int i = 0; i < [requestList count]; i++) {

        request = [requestList objectAtIndex:i];
        
       response=  [self sendHTTPRequest:[request objectAtIndex:kSGHTTPRequestParameter_Method]
                                  toURL:[request objectAtIndex:kSGHTTPRequestParameter_File]
                                   body:[request objectAtIndex:kSGHTTPRequestParameter_Body]
                             withParams:[request objectAtIndex:kSGHTTPRequestParameter_Params]
                              requestId:[request objectAtIndex:kSGHTTPRequestParameter_ResponseId]
                               callback:[NSNumber numberWithBool:NO]];

        if([response objectForKey:@"error"])
            break;
        else
            [responses addObject:[response objectForKey:@"responseObject"]];
    }
    
    
    NSMutableDictionary* responseObject = [NSMutableDictionary dictionary];
    [responseObject setObject:requestId forKey:@"requestId"];
    
    // If the response is not equal to the amount of requests sent,
    // then there was an error and the delegate should be notified.
    if([responses count] != [requestList count]) {
        [responseObject setObject:[response objectForKey:@"error"] forKey:@"error"];
                        
        if(callbackOnMainThread)
            [self performSelectorOnMainThread:@selector(failed:) withObject:responseObject waitUntilDone:NO];
        else
            [self failed:responseObject];
    } else {
        [responseObject setObject:responses forKey:@"responseObject"];
        
        if(callbackOnMainThread)
            [self performSelectorOnMainThread:@selector(succeeded:) withObject:responseObject waitUntilDone:NO];
        else
            [self succeeded:responseObject];                
        
    }
}

- (NSDictionary*) sendHTTPRequest:(NSString*)requestType
                            toURL:(NSString*)file 
                             body:(NSData*)body
                       withParams:(NSDictionary*)params 
                        requestId:(NSString*)requestId
                         callback:(NSNumber*)callback
{
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    
    if(!HTTPAuthorizer)
        HTTPAuthorizer = self;
    
    if(params && [params isKindOfClass:[NSNull class]])
        params = nil;
    
    if(body && [body isKindOfClass:[NSNull class]])
        body = nil;
    
    file = [NSString stringWithFormat:@"/%@%@", apiVersion, file];

    NSDictionary* returnDictionary = [HTTPAuthorizer dataAtURL:mainURL
                                                         file:file
                                                          body:body
                                                   parameters:params
                                                   httpMethod:requestType];
    

    NSData* data = [returnDictionary objectForKey:@"data"];
    NSHTTPURLResponse* response = [returnDictionary objectForKey:@"response"];
    NSError* error = [returnDictionary objectForKey:@"error"];
    NSDictionary* jsonObject = nil;;
    if(data && ![data isKindOfClass:[NSNull class]]) {
        NSError* error = nil;
        jsonObject = [NSDictionary dictionaryWithJSONData:data error:&error];
                
        if(error)
            SGLog(@"SGLocationService - Error occurred while parsing GeoJSON object: %@", [error description]);
    }
    

    if(jsonObject && error && ![error isKindOfClass:[NSNull class]])
        error = [NSError errorWithDomain:[jsonObject objectForKey:@"message"]
                                    code:[[jsonObject objectForKey:@"code"] intValue]
                                userInfo:nil];

    if((!error || (error && [error isKindOfClass:[NSNull class]])) && response && ![response isKindOfClass:[NSNull class]]) {
        NSInteger responseCode = [response statusCode];

        // Make sure we get 20x
        if((responseCode - 200) >= 0 && (responseCode - 200) < 100) {
            NSDictionary* responseObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                      requestId, @"requestId",
                                      jsonObject ? jsonObject : (NSObject*)[NSDictionary dictionary], @"responseObject",
                                            [NSNumber numberWithDouble:time], @"time", nil];

            
            if([callback boolValue]) {
                if(callbackOnMainThread)
                    [self performSelectorOnMainThread:@selector(succeeded:) withObject:responseObject waitUntilDone:NO];
                else
                    [self succeeded:responseObject];
            }

            return responseObject;
        }                 
    }
    
    if(!error || (error && [error isKindOfClass:[NSNull class]]))
       error = [NSError errorWithDomain:jsonObject ? [jsonObject objectForKey:@"message"] : @"Unknown"
                                   code:jsonObject ? [[jsonObject objectForKey:@"code"] intValue] : -1
                               userInfo:nil];
    
    
    NSDictionary* responseObject = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", error, @"error", nil];
    if([callback boolValue]) {
        if(callbackOnMainThread)
            [self performSelectorOnMainThread:@selector(failed:) withObject:responseObject waitUntilDone:NO];
        else
            [self failed:responseObject];
    }
    
    return responseObject;
}

- (void) pushMultiInvocationWithArgs:(NSArray*)args
{   
    NSMethodSignature* methodSignature = [self methodSignatureForSelector:@selector(sendMultipleHTTPRequest:requestId:)];
    NSInvocation* httpRequestInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [httpRequestInvocation setSelector:@selector(sendMultipleHTTPRequest:requestId:)];
    [httpRequestInvocation setTarget:self];    
    
    NSString* arg;
	for(int i = 0; i < [args count]; i++) {
        arg = [args objectAtIndex:i];
		[httpRequestInvocation setArgument:&arg atIndex:i + 2];
    }
	
	NSInvocationOperation* opertaion = [[[NSInvocationOperation alloc] initWithInvocation:httpRequestInvocation] autorelease];
	[operationQueue addOperation:opertaion];			
    
}

- (void) pushInvocationWithArgs:(NSArray*)args 
{	
    NSMethodSignature* methodSignature = [self methodSignatureForSelector:@selector(sendHTTPRequest:toURL:body:withParams:requestId:callback:)];
    NSInvocation* httpRequestInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [httpRequestInvocation setSelector:@selector(sendHTTPRequest:toURL:body:withParams:requestId:callback:)];
    [httpRequestInvocation setTarget:self];    

    NSString* arg;
	for(int i = 0; i < [args count]; i++) {
        arg = [args objectAtIndex:i];
		[httpRequestInvocation setArgument:&arg atIndex:i + 2];
    }
    
    NSNumber* no = [NSNumber numberWithBool:YES];
    [httpRequestInvocation setArgument:&no atIndex:[args count] + 2];

	NSInvocationOperation* opertaion = [[[NSInvocationOperation alloc] initWithInvocation:httpRequestInvocation] autorelease];
	[operationQueue addOperation:opertaion];			
}

#pragma mark -
#pragma mark Helper methods 

- (NSArray*) allTypes
{
    return [NSArray arrayWithObjects:kSGLocationType_Place, kSGLocationType_Person, kSGLocationType_Object,
            kSGLocationType_Note, kSGLocationType_Audio, kSGLocationType_Video, nil];
}


- (NSString*) getNextResponseId
{
    requestIdNumber++;
    return [NSString stringWithFormat:@"SGLocationService-%i", requestIdNumber];
}

- (void) dealloc
{
    [delegates release];
    [operationQueue release];
    [requestIds release];

#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED
    
    if(commitLog)
        [commitLog release];
    [cachedResponseIds release];
#endif
    
    [super dealloc];
}

@end
