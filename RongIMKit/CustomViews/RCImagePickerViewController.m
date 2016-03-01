//
//  RCImagePickerViewController.m
//
//  Created by Liv on 15/3/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//
#import "RCAssetHelper.h"
#import "RCImagePickerViewController.h"
#import "RCImagePickerCollectionViewCell.h"
#import "RCKitUtility.h"
@interface RCImagePickerViewController () <UICollectionViewDelegateFlowLayout>

- (void)dismissCurrentModelViewController;

@property(strong, nonatomic) UIImageView *ivPreview;

@property(strong, nonatomic) UIView *toolBar;
@property (nonatomic, strong) UIButton *btnFullImage;
@property (nonatomic, strong) UIButton *btnSend;
@end

@implementation RCImagePickerViewController

static NSString *const reuseIdentifier = @"Cell";

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.photos = [NSArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedStringFromTable(@"Cancel", @"RongCloudKit", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissCurrentModelViewController)];

    // Register cell classes
    [self.collectionView registerClass:[RCImagePickerCollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];

    // allow multiple selection
    self.collectionView.allowsMultipleSelection = YES;

    // long press for preview
    UILongPressGestureRecognizer *longTap =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapForPreview:)];
    longTap.minimumPressDuration = 0.15;
    [self.view addGestureRecognizer:longTap];

    // add preview
    _ivPreview = [[UIImageView alloc] initWithFrame:CGRectZero];
    _ivPreview.alpha = 0.0f;
    _ivPreview.contentMode = UIViewContentModeScaleAspectFit;
    _ivPreview.backgroundColor = [UIColor blackColor];
    _ivPreview.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapPreview:)];
    [_ivPreview addGestureRecognizer:tap];
    [_ivPreview setTranslatesAutoresizingMaskIntoConstraints:NO];
    if (self.navigationController) {
        [self.navigationController.view addSubview:_ivPreview];
        [self.navigationController.view
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_ivPreview]|"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_ivPreview)]];
        [self.navigationController.view
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_ivPreview]|"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_ivPreview)]];
    } else {
        [self.view addSubview:_ivPreview];
        [self.view
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_ivPreview]|"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_ivPreview)]];
        [self.view
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_ivPreview]|"
                                                                   options:kNilOptions
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(_ivPreview)]];
    }

    // add bottom bar
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    [_toolBar setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_toolBar];
    [_toolBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_toolBar(40)]-0-|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(_toolBar)]];
    [self.view
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_toolBar]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(_toolBar)]];

    // add butto for bottom bar
    _btnSend = [[UIButton alloc] init];
    [_btnSend setTitle:NSLocalizedStringFromTable(@"Send", @"RongCloudKit", nil) forState:UIControlStateNormal];
    [_btnSend setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_btnSend addTarget:self action:@selector(btnSendCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:_btnSend];
    
    UIButton *btnFullImage = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnFullImage setTitle:NSLocalizedStringFromTable(@"Full_Image", @"RongCloudKit", nil) forState:UIControlStateNormal];
    [btnFullImage setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btnFullImage setImage:[RCKitUtility imageNamed:@"deselect" ofBundle:@"RongCloud.bundle"] forState:UIControlStateNormal];
    [btnFullImage setTitle:NSLocalizedStringFromTable(@"Full_Image", @"RongCloudKit", nil) forState:UIControlStateSelected];
    [btnFullImage setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [btnFullImage setImage:[RCKitUtility imageNamed:@"selected" ofBundle:@"RongCloud.bundle"] forState:UIControlStateSelected];
    
    [btnFullImage addTarget:self action:@selector(btnFullImageCliced:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:btnFullImage];

    [_btnSend setTranslatesAutoresizingMaskIntoConstraints:NO];
    [btnFullImage setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [btnFullImage setImageEdgeInsets:UIEdgeInsetsMake(5, 1, 5, 0)];
//    [btnFullImage setTitleEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 0)];
    btnFullImage.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_btnSend(33)]"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_btnSend)]];
    
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[btnFullImage(33)]"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(btnFullImage)]];
    
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[btnFullImage(120)]"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(btnFullImage)]];
    
    [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_toolBar
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1
                                                          constant:-8]];
    [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:_btnSend
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_toolBar
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:-3]];
    
    [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:btnFullImage
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_toolBar
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1
                                                          constant:8]];
    [_toolBar addConstraint:[NSLayoutConstraint constraintWithItem:btnFullImage
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_toolBar
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:-3]];
    
    __weak RCImagePickerViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *path = [NSIndexPath indexPathForRow:weakSelf.photos.count - 1 inSection:0];
        [weakSelf.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    });
    self.btnFullImage = btnFullImage;
    
    [_btnSend setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [_btnSend setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.btnSend setEnabled:NO];
}

- (void)dismissCurrentModelViewController {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

/**
 *  点击发送图片
 *
 *  @param sender sender description
 */
- (void)btnSendCliced:(UIButton *)sender {
    
    
    NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
    NSMutableArray *selectedImages = [NSMutableArray new];
    int totalSize = 0;
    for (NSIndexPath *indexPath in indexPaths) {
        ALAsset *asset = self.photos[indexPath.row];
        totalSize += [asset defaultRepresentation].size;
    }
    
    BOOL fullResolution = YES;
    if (totalSize >= 50000000) {
        fullResolution = NO;
    }
    
    for (NSIndexPath *indexPath in indexPaths) {
        ALAsset *asset = self.photos[indexPath.row];
        
        CGImageRef imgRef;
        if (fullResolution) {
            imgRef = [[asset defaultRepresentation] fullResolutionImage];
        } else {
            imgRef = [[asset defaultRepresentation] fullScreenImage];
        }

        if (imgRef==nil) {
            imgRef=[asset thumbnail];
        }
        [selectedImages addObject:[UIImage imageWithCGImage:imgRef]];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerViewController:selectedImages:isSendFullImage:)]) {
        [self.delegate imagePickerViewController:self selectedImages:selectedImages isSendFullImage:self.btnFullImage.selected];
    }
    [self dismissCurrentModelViewController];
    
}

/**
 *  点击发送图片
 *
 *  @param sender sender description
 */
- (void)btnFullImageCliced:(UIButton *)sender {
    [sender setSelected:!sender.selected];
}


/**
 *  long press for preview
 *
 *  @param sender sender description
 */
- (void)onLongTapForPreview:(UILongPressGestureRecognizer *)gesture {
    if (![gesture.view isKindOfClass:self.view.class])
        return;
    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath) {
        [self showPreviewAtIndexPath:indexPath];
    }
}

/**
 *  hide preview
 *
 *  @param gesture gesture description
 */
- (void)onTapPreview:(UITapGestureRecognizer *)gesture {
    _ivPreview.alpha = 0.0f;
}

/**
 *  show preview
 *
 *  @param indexPath indexPath description
 */
- (void)showPreviewAtIndexPath:(NSIndexPath *)indexPath {
    _ivPreview.alpha = 1.0;
    ALAsset *asset = _photos[indexPath.row];
    if (asset) {
        _ivPreview.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
    }
    if (self.navigationController)
        [self.navigationController.view bringSubviewToFront:_ivPreview];
    else
        [self.view bringSubviewToFront:_ivPreview];
}

+ (instancetype)imagePickerViewController {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    RCImagePickerViewController *pickerViewController =
        [[RCImagePickerViewController alloc] initWithCollectionViewLayout:flowLayout];

    return pickerViewController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -  <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCImagePickerCollectionViewCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    // Configure the cell
    ALAsset *asset = self.photos[indexPath.row];
    if (asset) {
        [cell.imageView setImage:[UIImage imageWithCGImage:asset.thumbnail]];
    }
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //照片选择张数限制
    if (collectionView.indexPathsForSelectedItems.count > 9) {
        UIAlertView *alertView =
            [[UIAlertView alloc] initWithTitle:nil
                                       message:NSLocalizedStringFromTable(@"MaxNumSelectPhoto", @"RongCloudKit", nil)
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"RongCloudKit", nil)
                             otherButtonTitles:nil, nil];
        [alertView show];
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    } else {
        RCImagePickerCollectionViewCell *cell =
            (RCImagePickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell setSelected:YES];
    }
    
    if(collectionView.indexPathsForSelectedItems.count == 0){
        [self.btnSend setEnabled:NO];
    }else{
        [self.btnSend setEnabled:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    RCImagePickerCollectionViewCell *cell =
        (RCImagePickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setSelected:NO];
    if(collectionView.indexPathsForSelectedItems.count == 0){
        [self.btnSend setEnabled:NO];
    }else{
        [self.btnSend setEnabled:YES];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;

    flowLayout.minimumLineSpacing = 5;
    flowLayout.minimumInteritemSpacing = 5;
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect bounds = collectionView.bounds;
    float width = (bounds.size.width - 25) / 4;
    float height = width;
    return CGSizeMake(width, height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                             layout:(UICollectionViewLayout *)collectionViewLayout
    referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(self.view.bounds.size.width, 40);
}

@end
