//
//  SGGeoJSONEncoder.m
//  SGClient
//
//  Created by Derek Smith on 11/11/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGGeoJSONEncoder.h"

#import "SGLocationTypes.h"

#import "SGRecord.h"

@implementation SGGeoJSONEncoder

+ (NSArray*) recordsForGeoJSONObject:(NSDictionary*)geojsonObject
{
    NSMutableArray* records = [NSMutableArray array];
    NSArray* features = [geojsonObject features];
    for(NSDictionary* feature in features) {
     
        SGRecord* record = [SGGeoJSONEncoder recordForGeoJSONObject:feature];
        
        if(record)
            [records addObject:record];
        
    }
    
    return records;
}

+ (SGRecord*) recordForGeoJSONObject:(NSDictionary *)geojsonObject
{
    SGRecord* record = nil;
    if(!record) {
        
        record = [[[SGRecord alloc] init] autorelease];
        [record updateRecordWithGeoJSONObject:geojsonObject];
    }
    
    return record;
}

+ (NSDictionary*) geoJSONObjectForRecordAnnotations:(NSArray*)recordAnnotations
{
    NSMutableDictionary* geoJSONObject = nil;
    if(recordAnnotations && [recordAnnotations count]) {
        
        geoJSONObject = [NSMutableDictionary dictionary];
        [geoJSONObject setType:@"FeatureCollection"];
        
        NSMutableArray* features = [NSMutableArray array];
        for(id<SGRecordAnnotation> recordAnnotation in recordAnnotations) {
            
            NSDictionary* feature = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotation:recordAnnotation];
            if(feature)
                [features addObject:feature];
        }
        
        [geoJSONObject setFeatures:features];
    }
    
    return geoJSONObject;
}

+ (NSDictionary*) geoJSONObjectForRecordAnnotation:(id<SGRecordAnnotation>)recordAnnotation
{
    NSMutableDictionary* feature = nil;
    
    if(recordAnnotation) {
        feature = [NSMutableDictionary dictionary];
        [feature setType:@"Feature"];
    
        NSDictionary* properties = [recordAnnotation properties];
        [properties setValue:[recordAnnotation type] forKey:@"type"];
        [feature setProperties:properties];
    
        NSMutableArray* coordinates = [NSMutableArray arrayWithObjects:[NSNumber numberWithDouble:0.0],
                                       [NSNumber numberWithDouble:0.0], nil];
        [coordinates setLatitude:[recordAnnotation coordinate].latitude];
        [coordinates setLongitude:[recordAnnotation coordinate].longitude];
        NSMutableDictionary* geometry = [NSMutableDictionary dictionary];
        [geometry setType:@"Point"];
        [geometry setCoordinates:coordinates];
        [feature setValue:geometry forKey:@"geometry"];
    
        [feature setId:[recordAnnotation recordId]];
        [feature setExpires:[recordAnnotation expires]];
        [feature setCreated:[recordAnnotation created]];
    }
    
    return feature;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Utilities 
//////////////////////////////////////////////////////////////////////////////////////////////// 

// http://api.simplegeo.com/layer/com.simplegeo.global.brightkite.json
+ (NSString*) layerNameFromLayerLink:(NSString*)layerLink
{
    NSString* endpoint = nil;
    if(layerLink) {
        
        // This is realllly bad.
        NSArray* components = [layerLink componentsSeparatedByString:@"/"];
        endpoint = [[components lastObject] stringByDeletingPathExtension];
        
    }
    
    return endpoint;
}

@end
