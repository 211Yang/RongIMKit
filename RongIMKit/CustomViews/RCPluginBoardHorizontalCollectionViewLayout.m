//
//  HorizontalCollectionViewLayout.m
//  RongIMKit
//
//  Created by Liv on 15/3/16.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardHorizontalCollectionViewLayout.h"

#define RCPlaginBoardCellSize ((CGSize){ 60, 80 })
#define HorizontalItemsCount 4
#define VerticalItemsCount 2
#define ItemsPerPage (HorizontalItemsCount * VerticalItemsCount)

@implementation RCPluginBoardHorizontalCollectionViewLayout
float offsetWidth;
- (instancetype)init
{
    self = [super init];
    if (self) {
        _itemsPerSection = ItemsPerPage;
        self.itemSize = RCPlaginBoardCellSize;
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        offsetWidth = ([[UIScreen mainScreen] bounds].size.width - 60*4)/5;
    }
    return self;
}

- (CGSize)collectionViewContentSize {
    NSInteger sectionNumber = [self.collectionView numberOfSections];    
    CGSize size = self.collectionView.bounds.size;
    size.width = sectionNumber * size.width;
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* attributes = [NSMutableArray array];
    for(NSInteger i=0 ; i < self.collectionView.numberOfSections; i++) {
        for (NSInteger j=0 ; j < [self.collectionView numberOfItemsInSection:i]; j++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:j inSection:i];
            [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
        }
    }
    return attributes;

}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return NO;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path
{
    UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path]; //生成空白的attributes对象，其中只记录了类型是cell以及对应的位置是indexPath
    CGFloat horizontalInsets = (self.collectionView.bounds.size.width - HorizontalItemsCount * self.itemSize.width - 2 * offsetWidth)/(HorizontalItemsCount - 1);
    NSInteger currentPage = path.section;
    NSInteger currentRow = (NSInteger)floor((double)(path.row) / (double)HorizontalItemsCount);
    NSInteger currentColumn = path.row % HorizontalItemsCount;
    CGRect frame = attributes.frame;
    frame.origin.x = self.itemSize.width * currentColumn + offsetWidth + horizontalInsets * currentColumn + currentPage * self.collectionView.bounds.size.width;
    frame.origin.y = self.itemSize.height * currentRow + 15 * (currentRow + 1);
    frame.size.width = RCPlaginBoardCellSize.width;
    frame.size.height = RCPlaginBoardCellSize.height;
    attributes.frame = frame;
    return attributes;
}

@end