//
//  SGGeoJSONNSDictionary.m
//  SGClient
//
//  Created by Derek Smith on 2/1/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "GeoJSON+NSDictionary.h"

@implementation NSDictionary (SGGeoJSONObject)

- (NSString*) type
{
    return [self objectForKey:@"type"];
}

- (NSDictionary*) geometry
{
    NSDictionary* geometry = nil;
    if([self isFeature])
        geometry = [self objectForKey:@"geometry"];
    
    return geometry;
}

- (NSArray*) coordinates
{
    NSArray* coordinates = nil;
    if([self isPoint])
        coordinates = [self objectForKey:@"coordinates"];
    
    return coordinates;
}

- (NSDictionary*) properties
{
    NSDictionary* properties = nil;
    if([self isFeature])
            properties = [self objectForKey:@"properties"];
    
    return properties;
}

- (double) created
{
    double created = -1.0;

    if([self isFeature]) {
        NSNumber* num = [self objectForKey:@"created"];
        if(num)
            created = [num doubleValue];
    }
    
    return created;
}

- (double) expires
{
    double created = -1.0;
    if([self isFeature]) {
            
        NSNumber* num = [self objectForKey:@"expires"];
        if(num)
            created = [num doubleValue];
    }
    
    return created;    
}

- (NSString*) id
{
    NSString* objectId = nil;

    if([self isFeature])
        objectId = [self objectForKey:@"id"];
    
    return objectId;
}

- (NSArray*) features
{
    NSArray* features = nil;
    if([self isFeatureCollection])
        features = [self objectForKey:@"features"];
    
    return features;
}

- (NSString*) layerLink
{
    NSString* layerLink = nil;
    if([self isFeature])
        layerLink = [[self objectForKey:@"layerLink"] objectForKey:@"href"];
    
    return layerLink;
}

- (NSString*) selfLink
{
    NSString* selfLink = nil;
    if([self isFeature])
        selfLink = [[self objectForKey:@"selfLink"] objectForKey:@"href"];
    
    return selfLink;
}

- (BOOL) isFeature
{
    NSString* type = [self type];
    return type && [type isEqualToString:@"Feature"];
}

- (BOOL) isFeatureCollection;
{
    NSString* type = [self type];
    return type && [type isEqualToString:@"FeatureCollection"];
}

- (BOOL) isPoint
{
    NSString* type = [self type];
    return type && [type isEqualToString:@"Point"];
}

@end

@implementation NSMutableDictionary (SGGeoJSONObject)

- (void) setType:(NSString*)type
{
    [self setObject:type forKey:@"type"];
}

- (void) setGeometry:(NSDictionary*)geometry
{
    [self setObject:geometry forKey:@"geometry"];
}

- (void) setCoordinates:(NSArray*)coordinates
{
    [self setObject:coordinates forKey:@"coordinates"];
}

- (void) setProperties:(NSDictionary*)properties
{
    [self setObject:properties forKey:@"properties"];
}

- (void) setCreated:(double)created
{
    [self setObject:[NSNumber numberWithDouble:created]
             forKey:@"created"];
}

- (void) setExpires:(double)expires
{
    [self setObject:[NSNumber numberWithDouble:expires]
             forKey:@"expires"];
}

- (void) setId:(NSString*)id
{
    [self setObject:id forKey:@"id"];
}

- (void) setFeatures:(NSArray*)features
{
    [self setObject:features forKey:@"features"];
}

@end