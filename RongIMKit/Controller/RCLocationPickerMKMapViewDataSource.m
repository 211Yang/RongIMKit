//
//  RCLocationPickerMKMapViewDataSource.m
//  iOS-IMKit
//
//  Created by YangZigang on 14/11/5.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationPickerMKMapViewDataSource.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RCKitUtility.h"

@interface RCLocationPickerMKMapViewDataSource ()

@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, copy) OnPoiSearchResult completion;
@property(nonatomic, strong) CALayer *annotationLayer;
@property(nonatomic, assign) BOOL userLocationUpdated;
@property(nonatomic, strong) NSDate *firstTimeLocationChanged;
@property(nonatomic, strong) CLLocation *lastPoiLocation;

@end

@implementation RCLocationPickerMKMapViewDataSource

- (instancetype)init {
    if (self = [super init]) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        self.annotationLayer = [CALayer layer];
        UIImage *image = [RCKitUtility imageNamed:@"map_annotation" ofBundle:@"RongCloud.bundle"];
        self.annotationLayer.contents = (id)image.CGImage;
        self.annotationLayer.frame = CGRectMake(0, 0, 35, 35);
        [self.mapView setShowsUserLocation:YES];
        self.mapView.delegate = self;
        [self.mapView.userLocation addObserver:self
                                    forKeyPath:@"location"
                                       options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                       context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    MKUserLocation *userLocation = self.mapView.userLocation;
    if (userLocation.location.coordinate.longitude < 0.000001) {
        return;
    }

    if (!self.firstTimeLocationChanged) {
        self.firstTimeLocationChanged = [NSDate date];
    }
    if ([self.firstTimeLocationChanged timeIntervalSinceNow] < -1.5) {
        return;
    }

    self.userLocationUpdated = YES;
    MKCoordinateRegion coordinateRegion;
    coordinateRegion.center = userLocation.coordinate;
    coordinateRegion.span.latitudeDelta = 0.01;
    coordinateRegion.span.longitudeDelta = 0.01 * self.mapView.frame.size.width / self.mapView.frame.size.height;
    [self setMapViewCoordinateRegion:coordinateRegion animated:NO];
}

- (UIView *)mapView {
    return _mapView;
}

- (CALayer *)annotationLayer {
    return _annotationLayer;
}

- (void)userSelectPlaceMark:(id)placeMark {
}

- (CLLocationCoordinate2D)mapViewCenter {
    return [self.mapView centerCoordinate];
}

- (UIImage *)mapViewScreenShot {
    UIGraphicsBeginImageContextWithOptions(self.mapView.frame.size, NO, 0.0);
    [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    //    NSString *filePath = [[NSBundle mainBundle].bundlePath
    //    stringByAppendingString:@"/RongCloud.bundle/map_annotation.png"];
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.mapView.frame.size.height);
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), flipVertical);
    UIImage *imageAnnotation = [RCKitUtility imageNamed:@"map_annotation" ofBundle:@"RongCloud.bundle"];
    CGRect imageAnnotationFrame = CGRectMake(0, 0, 32, 32);
    imageAnnotationFrame.origin.y = self.mapView.frame.size.height / 2;
    imageAnnotationFrame.origin.x = self.mapView.frame.size.width / 2 - 16;
    CGContextDrawImage(UIGraphicsGetCurrentContext(), imageAnnotationFrame, imageAnnotation.CGImage);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //    CGRect cropRect = CGRectMake(0, 0, image.size.width, image.size.height);
    //    if (image.size.width > image.size.height) {
    //        cropRect.origin.x = ( image.size.width - image.size.height ) / 2;
    //        cropRect.size.width = cropRect.size.height * image.scale ;
    //    } else {
    //        cropRect.origin.y = ( image.size.height - image.size.width ) / 2;
    //        cropRect.size.height = cropRect.size.width * image.scale;
    //        cropRect.size.width *= image.scale;
    //    }
    CGRect rect;
    rect.origin = CGPointZero;
    rect.size = image.size;
    rect.size.height *= image.scale;
    rect.size.width *= image.scale;
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    // or use the UIImage wherever you like
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult {
    self.completion = poiSearchResult;
}

- (void)beginFetchPoisOfCurrentLocation {
    if (!self.completion) {
        DebugLog(@"请先使用函数setOnPoiSearchResult来设置POI搜索结果的回调block");
        return;
    }
}

- (void)setMapViewCenter:(CLLocationCoordinate2D)location animated:(BOOL)animated {
    [self.mapView setCenterCoordinate:location animated:animated];
}

- (void)setMapViewCoordinateRegion:(MKCoordinateRegion)coordinateRegion animated:(BOOL)animated {
    [self.mapView setRegion:coordinateRegion animated:animated];
}

- (void)fetchPOIInfo {
    if (self.lastPoiLocation == nil) {
        self.lastPoiLocation = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude
                                                          longitude:self.mapView.centerCoordinate.longitude];
    } else {
        CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude
                                                                 longitude:self.mapView.centerCoordinate.longitude];
        if ([self.lastPoiLocation distanceFromLocation:currentLocation] < 5) {
            return;
        }
        self.lastPoiLocation = currentLocation;
    }
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocationCoordinate2D locationCoordinate2D = self.mapView.centerCoordinate;
    CLLocation *location =
        [[CLLocation alloc] initWithLatitude:locationCoordinate2D.latitude longitude:locationCoordinate2D.longitude];
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                     //        for (CLPlacemark *placemark in placemarks) {
                     //            DebugLog(@"%@", [placemark description]);
                     //        }
                     if (placemarks.count) {
                         self.completion(placemarks, YES, NO, nil);
                     }
                   }];
}

- (NSString *)titleOfPlaceMark:(id)placeMark {
    if (![placeMark isKindOfClass:[CLPlacemark class]]) {
        return nil;
    }
    CLPlacemark *tPlaceMark = (CLPlacemark *)placeMark;
    return [tPlaceMark name];
}

- (CLLocationCoordinate2D)locationCoordinate2DOfPlaceMark:(id)placeMark {
    if (![placeMark isKindOfClass:[CLPlacemark class]]) {
        return CLLocationCoordinate2DMake(0, 0);
    }
    CLPlacemark *tPlaceMark = (CLPlacemark *)placeMark;
    return [tPlaceMark location].coordinate;
}

- (void)dealloc {
    [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
}

#pragma mark -
#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self fetchPOIInfo];
}
@end
