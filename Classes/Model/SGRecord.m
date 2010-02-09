// 
//  SGRecord.m
//  SGLocatorServices
//
//  Created by Derek Smith on 8/17/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGRecord.h"

#import "SGLocationTypes.h"

#import "GeoJSON+NSArray.h"
#import "GeoJSON+NSDictionary.h"

@interface SGRecord (Private)

- (BOOL) _isValid:(NSObject *)object;

@end

@implementation SGRecord 

@synthesize longitude, latitude, created, expires, layer, type, recordId, properties, layerLink, selfLink;

- (id) init
{
    if(self = [super init]) {
        
        latitude = 0.0;
        latitude = 0.0;
        recordId = nil;
        created = [[NSDate date] timeIntervalSince1970];
        expires = 0;
        type = @"object";
        layerLink = nil;
        selfLink = nil;
        properties = [[NSMutableDictionary alloc] init];
        layer = [[[NSBundle mainBundle] bundleIdentifier] retain];
        
        if(!layer)
            layer = @"missing";
    }
    
    return self;
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
        [self setRecordId:[geoJSONObject id]];

    }
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@: type=%@, layer=%@, lat=%f, long=%f, expires=%i, created=%i>", self.recordId, self.type,
            self.layer, self.latitude, self.longitude, (int)self.expires, (int)self.created];
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
    
    [super dealloc];
}

@end
