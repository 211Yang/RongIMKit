//
//  RCAlbumListViewController.m
//  RongIMKit
//
//  Created by MiaoGuangfa on 6/4/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCAlbumListViewController.h"
#import "RCAssetHelper.h"
#import "RCImagePickerViewController.h"

#import "RCAlbumListCell.h"

static NSString *cellReuseIdentifier = @"album.cell.reuse.index";

@interface RCAlbumListViewController () <RCImagePickerViewControllerDelegate>
- (void)dismissCurrentModelViewController;
@end

@implementation RCAlbumListViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.libraryList = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[RCAlbumListCell class] forCellReuseIdentifier:cellReuseIdentifier];
    self.title = NSLocalizedStringFromTable(@"Albums", @"RongCloudKit", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"RongCloudKit", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissCurrentModelViewController)];

    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
}
- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.libraryList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCAlbumListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    // Configure the cell...
    ALAssetsGroup *alAssetGroup_ = [self.libraryList objectAtIndex:indexPath.row];
    
    NSString * groupName_ = [alAssetGroup_ valueForProperty:ALAssetsGroupPropertyName];
    CGImageRef posterImage_CGImageRef_ = [alAssetGroup_ posterImage];
    UIImage *posterImage_ = [UIImage imageWithCGImage:posterImage_CGImageRef_];
    
    cell.imageView.image = posterImage_;
    cell.textLabel.text = [groupName_ stringByAppendingFormat:@" (%ld)", (long)[alAssetGroup_ numberOfAssets]];
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(&*self)weakSelf = self;
    
    ALAssetsGroup *selected_alAssetGroup_ = [self.libraryList objectAtIndex:indexPath.row];
    
    RCAssetHelper *sharedAssetHelper = [RCAssetHelper shareAssetHelper];
    
    [sharedAssetHelper getPhotosOfGroup:selected_alAssetGroup_ results:^(NSArray *photos) {
        DebugLog(@"%lu", (unsigned long)[photos count]);
        
        if (nil != photos && [photos count] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                RCImagePickerViewController *imagePickerVC = [RCImagePickerViewController imagePickerViewController];
                imagePickerVC.photos = photos;
                imagePickerVC.delegate = weakSelf;
                
                NSString * groupName_ = [selected_alAssetGroup_ valueForProperty:ALAssetsGroupPropertyName];
                imagePickerVC.title = groupName_;
                
                [weakSelf.navigationController pushViewController:imagePickerVC animated:YES];
            });
        }
    }];
}

- (void)imagePickerViewController:(RCImagePickerViewController *)imagePickerViewController selectedImages:(NSArray *)selectedImages isSendFullImage:(BOOL)enable
{
    if ([self.delegate respondsToSelector:@selector(albumListViewController:selectedImages:isSendFullImage:)]) {
        [self.delegate albumListViewController:self selectedImages:selectedImages isSendFullImage:enable];
    }
}

@end
