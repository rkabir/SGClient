// 
//  SGRecord.m
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

#import "SGRecord.h"

#import "SGLocationTypes.h"

#import "SGGeoJSONEncoder.h"
#import "GeoJSON+NSArray.h"
#import "GeoJSON+NSDictionary.h"
#import "SGGeoJSON+NSDictionary.h"

#import "SGLocationService.h"

@interface SGRecord (Private) <SGLocationServiceDelegate>

- (BOOL) _isValid:(NSObject *)object;

@end

@implementation SGRecord
@synthesize longitude, latitude, created, expires, layer, recordId, properties, layerLink, selfLink, history;
@dynamic type;

- (id) init
{
    if(self = [super init]) {
        
        latitude = 0.0;
        latitude = 0.0;
        recordId = nil;
        created = [[NSDate date] timeIntervalSince1970];
        expires = 0;
        type = nil;
        layerLink = nil;
        selfLink = nil;
        properties = [[NSMutableDictionary alloc] init];
        layer = nil;
        historyQuery = nil;
        
        if(!layer)
            layer = @"missing";
    }
    
    return self;
}

#pragma mark -
#pragma mark Accessor methods 

/* The type object needs to be stored in the properties dictionary */
- (void) setType:(NSString*)newType
{
    if(!properties)
        properties = [[NSMutableDictionary alloc] init];
    
    [properties setObject:newType forKey:@"type"];
}

- (NSString*) type
{
    NSString* recordType = kSGLocationType_Object;
    if(properties && [properties objectForKey:@"type"])
        recordType = [properties objectForKey:@"type"];
    
    return recordType;
}

#pragma mark -
#pragma mark MKAnnotation methods 

- (CLLocationCoordinate2D) coordinate
{    
    CLLocationCoordinate2D myCoordinate = {[self latitude], [self longitude]};
    
    return myCoordinate;
}

- (NSString*) title
{
    return recordId;
}

- (NSString*) subtitle
{
    return layer;
}

#pragma mark -
#pragma mark Dictionary/Records  

- (void) updateRecordWithGeoJSONObject:(NSDictionary*)geoJSONObject
{
    if(geoJSONObject) {
        
        NSDictionary* geometry = [geoJSONObject geometry];
        
        if(geometry) {
            
            NSArray* coordinates = [geometry coordinates];        
            if([self _isValid:coordinates]) {
     
                [self setLatitude:[coordinates latitude]];
                [self setLongitude:[coordinates longitude]];
            }
            
        }
        
        NSDictionary* prop = [geoJSONObject properties];
        if([self _isValid:prop]) 
            [self.properties addEntriesFromDictionary:prop];
        
        [self setExpires:[geoJSONObject expires]];
        [self setCreated:[geoJSONObject created]];
        [self setRecordId:[geoJSONObject recordId]];
        [self setLayer:[SGGeoJSONEncoder layerNameFromLayerLink:[geoJSONObject layerLink]]];
    }
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: type=%@, layer=%@, lat=%f, long=%f, expires=%i, created=%i>", self.recordId, self.type,
            self.layer, self.latitude, self.longitude, (int)self.expires, (int)self.created];
}

- (NSString*) getHistory:(int)limit
{
    SGLocationService* sharedLocationService = [SGLocationService sharedLocationService];
    if(!historyQuery) {
        historyQuery = [[SGHistoryQuery alloc] init];
        [sharedLocationService addDelegate:self];
    }

    historyQuery.recordId = recordId;
    historyQuery.layer = layer;
    historyQuery.cursor = nil;
    historyQuery.limit = limit;
    
    return [sharedLocationService history:historyQuery];
}

#pragma mark -
#pragma mark SGLocationService delegate methods 

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)requestId responseObject:(NSObject*)responseObject
{
    if(historyQuery && [historyQuery.requestId isEqualToString:requestId]) {
        
        NSDictionary* newHistory = (NSDictionary*)responseObject;
        history = [newHistory retain];
     
        SGLocationService* sharedLocationService = [SGLocationService sharedLocationService];
        [sharedLocationService removeDelegate:self];
    }
}

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    ;
}

#pragma mark -
#pragma mark Helper methods 
 
- (BOOL) _isValid:(NSObject*)object
{
    return object && ![object isKindOfClass:[NSNull class]];
}

- (void) dealloc
{
    [recordId release];
    [type release];
    [layer release];
    [properties release];
    [layerLink release];
    [selfLink release];

    [historyQuery release];
    [history release];
    
    [[SGLocationService sharedLocationService] removeDelegate:self];
    
    [super dealloc];
}

@end
