/*
 *  SGPointHelper.h
 *  SGClient
 *
 *  Created by Derek Smith on 6/10/10.
 *  Copyright 2010 SimpleGeo. All rights reserved.
 *
 */

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

extern CLLocationCoordinate2D* SGLonLatArrayToCLLocationCoordArray(NSArray* lonLatArray);
extern NSArray* SGCLLocationCoordArrayToLonLatArray(CLLocationCoordinate2D* coordArray, int length);

extern MKMapRect SGGetAxisAlignedBoundingBox(CLLocationCoordinate2D* coordArray, int length);

