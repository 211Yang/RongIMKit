//
//  RCLocationPickerViewController.m
//  iOS-IMKit
//
//  Created by YangZigang on 14/10/31.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCLocationPickerViewController.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import <MapKit/MapKit.h>
#import "RCIM.h"
#import "RCLocationPickerMKMapViewDataSource.h"

@interface RCLocationPickerViewController () <RCLocationPickerViewControllerDataSource>

@property(nonatomic, strong) UIView *mapView;
@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) CALayer *annotationLayer;

@property(nonatomic, strong) NSMutableArray *pois;
@property(nonatomic, assign) int currentSelectedPoi;
@property(nonatomic, strong) UIView *tableViewFooterView;
@property(nonatomic, strong) UILabel *moreLabel;
@property(nonatomic, strong) UIActivityIndicatorView *busyIndicator;
@property(nonatomic, assign) BOOL hasMore;

/** 设置UINavigationController的NavigationBar

 设置返回按钮、标题、完成按钮。用户可以根据情况编写自己的configureNavigationBar。
 */
- (void)configureNavigationBar;

@end

@implementation RCLocationPickerViewController

- (instancetype)initWithDataSource:(id<RCLocationPickerViewControllerDataSource>)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource
                setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore, NSError *error) {
                  [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
                }];
        }
    }
    return self;
}
- (instancetype)init {
    if (self = [super init]) {
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource
                setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore, NSError *error) {
                  [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
                }];
        }
    }
    return self;
}
- (void)setOnPoiSearchResult:(OnPoiSearchResult)poiSearchResult {
    [_dataSource setOnPoiSearchResult:poiSearchResult];
}

- (id<RCLocationPickerViewControllerDataSource>)dataSource {
    if (!_dataSource) {
        _dataSource = self;
        _dataSource = [[RCLocationPickerMKMapViewDataSource alloc] init];
    }
    return _dataSource;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        __weak typeof(self) weakSelf = self;
        if ([self.dataSource respondsToSelector:@selector(setOnPoiSearchResult:)]) {
            [self.dataSource
                setOnPoiSearchResult:^(NSArray *pois, BOOL clearPreviousResult, BOOL hasMore, NSError *error) {
                  [weakSelf onPoiSearchResult:pois clearPreviousResult:clearPreviousResult hasMore:hasMore error:error];
                }];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    if (!self.mapViewContainer) {
        [self loadMapViewContainer];
    }

    if (!self.title) {
        self.navigationItem.title = self.title = NSLocalizedStringFromTable(@"PickLocation", @"RongCloudKit", nil);
    }

    self.mapView = [self.dataSource mapView];
    self.mapView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6f].CGColor;
    self.mapView.layer.shadowRadius = 3.0f;
    self.mapView.clipsToBounds = NO;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapView.frame = self.mapViewContainer.bounds;
    [self.mapViewContainer addSubview:self.mapView];
    CALayer *annotationLayer = [self.dataSource annotationLayer];
    annotationLayer.anchorPoint = CGPointMake(0.5, 1.0f);
    annotationLayer.position =
        CGPointMake(CGRectGetMidX(self.mapViewContainer.bounds), CGRectGetMidY(self.mapViewContainer.bounds));
    [self.mapViewContainer.layer addSublayer:annotationLayer];
    self.annotationLayer = annotationLayer;

    frame.origin.y = frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    self.tableViewFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.tableViewFooterView.backgroundColor = [UIColor clearColor];
    self.moreLabel = [[UILabel alloc] initWithFrame:self.tableViewFooterView.bounds];
    self.moreLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.moreLabel.text = NSLocalizedStringFromTable(@"More", @"RongCloudKit", nil);
    self.moreLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableViewFooterView addSubview:self.moreLabel];
    self.busyIndicator =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.busyIndicator.center =
        CGPointMake(CGRectGetMidX(self.tableViewFooterView.bounds), CGRectGetMidY(self.tableViewFooterView.bounds));
    [self.tableViewFooterView addSubview:self.busyIndicator];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.tableViewFooterView.bounds;
    [button addTarget:self action:@selector(loadMorePoi:) forControlEvents:UIControlEventTouchUpInside];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableViewFooterView addSubview:button];

    [self configureNavigationBar];

    [self startStandardUpdates];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSuspend)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appResume)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)appSuspend {
    if (nil != self.locationManager) {
        if (IOS_FSystenVersion > 7.99) {
            [self stopTrackingLocation];
        } else {
            [self.locationManager stopUpdatingLocation];
        }
    }
}

- (void)appResume {
    if (nil != self.locationManager) {
        if (IOS_FSystenVersion > 7.99) {
            [self startTrackingLocation];
        } else {
            [self.locationManager startUpdatingLocation];
        }
    }
}
- (void)loadMapViewContainer {
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapViewContainer = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:self.mapViewContainer];
}

- (void)viewDidLayoutSubviews {
    CGRect frame = self.view.bounds;
    frame.size.height /= 2;
    self.mapViewContainer.frame = frame;
    self.annotationLayer.position =
        CGPointMake(CGRectGetMidX(self.mapViewContainer.bounds), CGRectGetMidY(self.mapViewContainer.bounds));

    frame.origin.y = frame.size.height;
    self.tableView.frame = frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)configureNavigationBar {
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 6, 42, 23);
    UIImageView *backImg = [[UIImageView alloc] initWithImage:IMAGE_BY_NAMED(@"navigator_btn_back")];
    backImg.frame = CGRectMake(-10, 0, 22, 22);
    [backBtn addSubview:backImg];
    UILabel *backText = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 40, 22)];
    backText.text = NSLocalizedStringFromTable(@"Back", @"RongCloudKit", nil);
    backText.font = [UIFont systemFontOfSize:15];
    [backText setBackgroundColor:[UIColor clearColor]];
    [backText setTextColor:[RCIM sharedRCIM].globalNavigationBarTintColor];
    [backBtn addSubview:backText];
    [backBtn addTarget:self action:@selector(leftBarButtonItemPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    [self.navigationItem setLeftBarButtonItem:leftButton];

    UIBarButtonItem *item =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Done", @"RongCloudKit", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(rightBarButtonItemPressed:)];
    item.tintColor = [RCIM sharedRCIM].globalNavigationBarTintColor;
    self.navigationItem.rightBarButtonItem = item;

    //    UILabel* titleLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    //    titleLab.font = [UIFont systemFontOfSize:18];
    //    [titleLab setBackgroundColor:[UIColor clearColor]];
    //    titleLab.textColor = [UIColor whiteColor];
    //
    //    titleLab.textAlignment = NSTextAlignmentCenter;
    //    titleLab.tag = 1000;
    //    self.navigationItem.titleView=titleLab;
    //    titleLab.text = self.title;
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    //    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)setBusyIndicator:(BOOL)busy hidden:(BOOL)hidden {
    if (hidden) {
        self.tableView.tableFooterView = nil;
        return;
    }
    if (!self.tableViewFooterView.superview) {
        self.tableView.tableFooterView = self.tableViewFooterView;
    }
    self.moreLabel.hidden = busy;
    self.busyIndicator.hidden = !busy;
}

- (void)startStandardUpdates {
    // return;

    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }

    //    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
    //        [self.locationManager requestWhenInUseAuthorization];
    //        DebugLog(@"requestWhenInUseAuthorization");
    //    }
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 200; // meters

    if (IOS_FSystenVersion > 7.99) {
        [self startTrackingLocation];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark -
#pragma mark CCLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];

    [(MKMapView *)self.mapView setCenterCoordinate:location.coordinate];
    MKCoordinateRegion coordinateRegion;
    coordinateRegion.center = location.coordinate;
    coordinateRegion.span.latitudeDelta = 0.01;
    coordinateRegion.span.longitudeDelta = 0.01;
    [self.dataSource setMapViewCoordinateRegion:coordinateRegion animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DebugLog(@"获取用户位置出错： %@", [error description]);
}

- (void)rightBarButtonItemPressed:(id)sender {
    if (self.delegate) {
        [self.delegate locationPicker:self
                    didSelectLocation:[self currentLocationCoordinate2D]
                         locationName:[self currentLocationName]
                        mapScreenShot:[self currentMapScreenShot]];
    }
}

- (CLLocationCoordinate2D)currentLocationCoordinate2D {
    return [self.dataSource mapViewCenter];
}

- (UIImage *)currentMapScreenShot {
    return [self.dataSource mapViewScreenShot];
}

- (NSString *)currentLocationName {
    if (self.pois) {
        @try {
            id placeMark = [self.pois objectAtIndex:self.currentSelectedPoi];
            return [self.dataSource titleOfPlaceMark:placeMark];
        } @catch (NSException *exception) {
        } @finally {
        }
    }
    CLLocationCoordinate2D location = [self currentLocationCoordinate2D];
    NSString *_longitude = NSLocalizedStringFromTable(@"Longitude", @"RongCloudKit", nil);
    NSString *_latitude = NSLocalizedStringFromTable(@"Latitude", @"RongCloudKit", nil);

    NSString *_f_longitude = [_longitude stringByAppendingFormat:@":%lf", location.longitude];
    NSString *_f_latitude = [_latitude stringByAppendingFormat:@":%lf", location.latitude];

    NSString *_current_locationName = [_f_longitude stringByAppendingFormat:@" %@", _f_latitude];
    return _current_locationName;
    // return [NSString stringWithFormat:@"经度:%lf 纬度:%lf", location.longitude, location.latitude];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation   efore navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadMorePoi:(id)sender {
    [self setBusyIndicator:YES hidden:NO];
    [self.dataSource beginFetchPoisOfCurrentLocation];
}

- (void)onPoiSearchResult:(NSArray *)pois
      clearPreviousResult:(BOOL)clearPreviousResult
                  hasMore:(BOOL)hasMore
                    error:(NSError *)error {
    if (!self.pois) {
        self.pois = [NSMutableArray array];
    }
    if (clearPreviousResult) {
        [self.pois removeAllObjects];
        self.currentSelectedPoi = 0;
    }
    [self.pois addObjectsFromArray:pois];
    [self.tableView reloadData];
    if (hasMore) {
        [self setBusyIndicator:NO hidden:NO];
    } else {
        [self setBusyIndicator:NO hidden:YES];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"LocationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    id placeMark = [self.pois objectAtIndex:indexPath.row];
    cell.textLabel.text = [self.dataSource titleOfPlaceMark:placeMark];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    if (indexPath.row == self.currentSelectedPoi) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.dataSource userSelectPlaceMark:[self.pois objectAtIndex:indexPath.row]];
    self.currentSelectedPoi = (int)indexPath.row;
    [self.tableView reloadData];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height < 30) {
        [self.dataSource beginFetchPoisOfCurrentLocation];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!self.tableView.tableFooterView) {
        return;
    }
    if (scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height < 30) {
        [self.dataSource beginFetchPoisOfCurrentLocation];
        [self setBusyIndicator:YES hidden:NO];
    }
}

#pragma ios8
- (void)startTrackingLocation {

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        if (self.locationManager) {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];
            }
        }
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
               status == kCLAuthorizationStatusAuthorizedAlways) {
        if (self.locationManager) {
            [_locationManager startUpdatingLocation];
        }
    }
}
- (void)stopTrackingLocation {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
               status == kCLAuthorizationStatusAuthorizedAlways) {
        if (self.locationManager) {
            [_locationManager stopUpdatingLocation];
        }
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
    case kCLAuthorizationStatusAuthorizedAlways:
        [self startTrackingLocation];
        break;
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        DebugLog(@"Got authorization, start tracking location");
        [self startTrackingLocation];
        break;
    case kCLAuthorizationStatusNotDetermined:
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }

    default:
        break;
    }
}

- (void)dealloc {
    if (nil != self.locationManager) {
        if (IOS_FSystenVersion > 7.99) {
            [self stopTrackingLocation];
        } else {
            [self.locationManager stopUpdatingLocation];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
