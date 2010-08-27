//
//  SGGeoJSONNSDictionary.m
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

#import "GeoJSON+NSDictionary.h"

@interface NSDictionary (GeoJSONObejctPrivate)

- (BOOL) isType:(NSString *)type;

@end

@implementation NSDictionary (GeoJSONObject)

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
    if([self isPoint] || [self isPolygon] || [self isMultiPolygon])
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

- (NSArray*) geometries
{
    NSArray* geometries = nil;
    if([self isGeometryCollection])
        geometries = [self objectForKey:@"geometries"];
    
    return geometries;
}

- (NSArray*) features
{
    NSArray* features = nil;
    if([self isFeatureCollection])
        features = [self objectForKey:@"features"];
    
    return features;
}

- (BOOL) isFeature
{
    return [self isType:@"Feature"];
}

- (BOOL) isFeatureCollection;
{
    return [self isType:@"FeatureCollection"];
}

- (BOOL) isGeometryCollection
{
    return [self isType:@"GeometryCollection"];
}

- (BOOL) isPoint
{
    return [self isType:@"Point"];
}

- (BOOL) isMultiPolygon
{
    return [self isType:@"MultiPolygon"];
}

- (BOOL) isPolygon
{
    return [self isType:@"Polygon"];
}

- (BOOL) isType:(NSString*)type
{
    NSString* featureType = [self objectForKey:@"type"];
    return featureType && [featureType isEqualToString:type];
}

@end

@implementation NSMutableDictionary (GeoJSONObject)

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

- (void) setFeatures:(NSArray*)features
{
    [self setObject:features forKey:@"features"];
}

- (void) setGeometries:(NSArray*)geometries
{
    [self setObject:geometries forKey:@"geometries"];
}

- (void) addGeometry:(NSDictionary*)geometry
{
    NSMutableArray* geometries = [NSMutableArray arrayWithObject:geometry];
    [geometries addObjectsFromArray:[self geometries]];
    [self setGeometries:geometries];
}

@end