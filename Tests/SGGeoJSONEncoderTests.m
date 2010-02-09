//
//  SGGeoJsonEncoderTests.m
//  SGClient
//
//  Created by Derek Smith on 12/18/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import <Foundation/Foundation.h>
#import "SGClient.h"

@interface SGGeoJsonEncoderTests : SenTestCase {
    
}

@end


@implementation SGGeoJsonEncoderTests

- (void) validateJSONObject:(NSDictionary*)dictionary record:(SGRecord*)record
{
    STAssertTrue([[dictionary type] isEqualToString:@"FeatureCollection"], @"Initial record should be of type FeatureCollection.");
    
    NSDictionary* feature = [[dictionary features] objectAtIndex:0];
    NSLog([[feature geometry] description]);
    double value = [[[feature geometry] coordinates] latitude];
    STAssertTrue(value == record.latitude, @"Latitude should be %f, but was %f.", record.latitude, value);
    value = [[[feature geometry] coordinates] longitude];
    STAssertTrue(value == record.longitude, @"Longitude should be %f, but was %f.", record.longitude, value);
        
    value = [feature expires];
    STAssertTrue([feature expires] == record.expires, @"Expiration date should be %f, but was %f", record.expires, value);
    
    value = [feature created];
    STAssertTrue(value == record.created, @"Creation date should be %f, but was %f", record.created, value);
    
    STAssertTrue([[feature id] isEqualToString:record.recordId], @"Record ID should be %@", record.recordId);
    
    NSDictionary* properties = [feature properties];
    STAssertTrue([[properties objectForKey:@"me"] isEqualToString:@"you"], @"Me should map to you.");
    STAssertTrue([[properties objectForKey:@"number"] intValue] == 2, @"number should map to the integer value 2");    
}

- (void) testRecordAnnotationToGeoJSONObject
{
    SGRecord* record = [[SGRecord alloc] init];
    record.recordId = @"12345";
    record.layer = @"com.you.complete.me";
    record.latitude = 99.0;
    record.longitude = 90.0;
    record.expires = 99.0;
    record.created = 199.0;
    [record.properties setObject:@"you" forKey:@"me"];
    [record.properties setObject:[NSNumber numberWithInt:2] forKey:@"number"];
    
    NSDictionary* dictionary = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotations:[NSArray arrayWithObject:record]];
    [self validateJSONObject:dictionary record:record];    
}

- (void) testGetRecordIdFromGeoJSONObject
{
    SGRecord* record = [[[SGRecord alloc] init] retain];
    record.recordId = @"sup123";

    NSDictionary* dictionary = [[SGGeoJSONEncoder geoJSONObjectForRecordAnnotations:[NSArray arrayWithObject:record]] retain];
    NSString* recordId = [[[dictionary features] objectAtIndex:0] id];
    STAssertTrue([recordId isEqualToString:record.recordId], @"The record id should be equal to %@, but was %@", record.recordId, recordId);
    [dictionary release];
}

@end
