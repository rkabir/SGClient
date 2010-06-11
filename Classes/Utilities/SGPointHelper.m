/*
 *  SGPointHelper.c
 *  SGClient
 *
 *  Created by Derek Smith on 6/10/10.
 *  Copyright 2010 SimpleGeo. All rights reserved.
 *
 */

#include "SGPointHelper.h"

CLLocationCoordinate2D* SGLonLatArrayToCLLocationCoordArray(NSArray* lonLatArray) {
    int count = [lonLatArray count];
    CLLocationCoordinate2D* polyline = malloc(sizeof(CLLocationCoordinate2D)*count);
    NSArray* coordinate = nil;
    for(int i = 0; i < count; i++) {
        coordinate = [lonLatArray objectAtIndex:i];
        CLLocationCoordinate2D coord = {[[coordinate objectAtIndex:1] doubleValue], [[coordinate objectAtIndex:0] doubleValue]};
        polyline[i] = coord;
    }
    
    return polyline;
}

NSArray* SGCLLocationCoordArrayToLonLatArray(CLLocationCoordinate2D* coordArray, int length) {
    NSMutableArray* coordinates = [NSMutableArray arrayWithCapacity:length];
    for(int i = 0; i < length; i++) {
        CLLocationCoordinate2D coord = coordArray[i];
        [coordinates addObject:[NSArray arrayWithObjects:[NSNumber numberWithDouble:coord.longitude],
                                                         [NSNumber numberWithDouble:coord.latitude],
                                                          nil]];
    }
    
    return coordinates;
}

MKMapRect SGGetAxisAlignedBoundingBox(CLLocationCoordinate2D* coordArray, int length) {

    CLLocationDegrees bigLat, bigLon, smallLat, smallLon = 0;
    for(int i = 0; i < length; i++) {
        CLLocationDegrees lat = coordArray[i].latitude;
        CLLocationDegrees lon = coordArray[i].longitude;
        if(lat > bigLat)
            bigLat = lat;
        
        if(lat < smallLat)
            smallLat = lat;
        
        if(lon > bigLon)
            bigLon = lon;
        
        if(lon < smallLon)
            smallLon = lon;
    }
    
    double width = sqrt(pow((bigLon - smallLon), 2));
    double height= sqrt(pow((bigLat - smallLat), 2));
    double x = bigLat - width;
    double y = bigLon - height;
    
    return MKMapRectMake(x, y, width, height);
}
