//
//  RCPluginBoard.m
//  CollectionViewTest
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardView.h"
#import "RCPluginBoardItem.h"
#import "RCPluginBoardHorizontalCollectionViewLayout.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCPluginBoardItem.h"

#define RCPluginBoardCell @"RCPluginBoardCell"

@interface RCPluginBoardView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong, nonatomic) RCPluginBoardHorizontalCollectionViewLayout *layout;
- (void)insertItem:(RCPluginBoardItem *)item atIndex:(NSInteger)index;
@end

@implementation RCPluginBoardView

- (instancetype)initWithFrame:(CGRect)frame {
    self.layout = [RCPluginBoardHorizontalCollectionViewLayout new];
    self = [super initWithFrame:frame collectionViewLayout:self.layout];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        self.pagingEnabled = YES;
        self.allItems = [@[] mutableCopy];
        self.scrollEnabled = YES;
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        [self setBackgroundColor:[UIColor colorWithRed:248 / 255.f green:248 / 255.f blue:248 / 255.f alpha:1]];
        [self registerClass:[RCPluginBoardItem class] forCellWithReuseIdentifier:RCPluginBoardCell];
    }
    return self;
}


-(void)insertItemWithImage:(UIImage*)image title:(NSString*)title atIndex:(NSInteger)index tag:(NSInteger)tag
{
    RCPluginBoardItem *__item = [[RCPluginBoardItem alloc]initWithTitle:title image:image tag:tag];
    [self insertItem:__item atIndex:index];
}

-(void)insertItemWithImage:(UIImage*)image title:(NSString*)title tag:(NSInteger)tag
{
    [self insertItemWithImage:image title:title atIndex:self.allItems.count tag:tag];
}

- (void)insertItem:(RCPluginBoardItem *)item atIndex:(NSInteger)index {
    if (item) {
        if (index > self.allItems.count) {
            index = self.allItems.count;
        }
        [_allItems insertObject:item atIndex:index];
    }
    [self reloadData];
}

-(void)updateItemAtIndex:(NSInteger)index image:(UIImage*)image title:(NSString*)title
{
    if (index >= 0 && index < self.allItems.count) {
        RCPluginBoardItem *item = self.allItems[index];
        
        if (image) {
            item.image = image;
        }
        if (title) {
            item.title = title;
        }
        
        [self reloadData];
    }
}

-(void)updateItemWithTag:(NSInteger)tag image:(UIImage*)image title:(NSString*)title
{
    for (int i = 0; i < self.allItems.count; i++) {
        RCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            if (image) {
                item.image = image;
            }
            if (title) {
                item.title = title;
            }
            [self reloadData];
        }
    }
}

- (void)removeItemWithTag:(NSInteger)tag
{
    for (int i = 0; i < _allItems.count; i++) {
        RCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            [_allItems removeObjectAtIndex:i];
            [self reloadData];
        }
    }
}
- (void)removeItemAtIndex:(NSInteger)index
{
    if (_allItems) {
        NSInteger _count = [_allItems count];

        if (index >= _count) {
            return;
        }

        [_allItems removeObjectAtIndex:index];
        [self reloadData];
    }
}
- (void)removeAllItems
{
    [self.allItems removeAllObjects];
    [self reloadData];
}

- (void)setPageTips:(NSInteger)pages {
    if (pages == 1) {
        //一页不显示分页
        return;
    }
    
    NSString *currentPage = @"•";
    NSString *otherPage = @"◦";
    
    for (int i = 0; i < pages; i++) {
        UILabel *tips = [[UILabel alloc] initWithFrame:CGRectMake(i * self.bounds.size.width, self.bounds.size.height - 25, self.bounds.size.width, 8)];
        tips.textAlignment = NSTextAlignmentCenter;
        tips.textColor = [UIColor colorWithRed:137 / 255.f green:137 / 255.f blue:137 / 255.f alpha:1];
        
        NSMutableString *mutableTips = [[NSMutableString alloc] init];
        for (int j = 0; j < pages; j++) {
            if (i == j) {
                [mutableTips appendString:currentPage];
            } else {
                [mutableTips appendString:otherPage];
            }
        }
        
        tips.text = [mutableTips copy];
        [self addSubview:tips];
    }
}

#pragma mark-- UICollectionViewDataSource
//定义展示的UICollectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ((section + 1) * self.layout.itemsPerSection >= self.allItems.count) {
        return self.allItems.count - section * self.layout.itemsPerSection;
    } else {
        return self.layout.itemsPerSection;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger sectionNumber = (NSInteger)ceilf((double)self.allItems.count / self.layout.itemsPerSection);
    [self setPageTips:sectionNumber];

    return sectionNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = RCPluginBoardCell;
    RCPluginBoardItem *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    RCPluginBoardItem *item = _allItems[indexPath.row + indexPath.section * self.layout.itemsPerSection];
    cell.title = item.title;
    cell.image = item.image;
    cell.tag = item.tag;
    [cell layoutSubviews];
    return cell;
}
#pragma mark--UICollectionViewDelegate
// UICollectionView被选中时调用的方法
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_pluginBoardDelegate && [_pluginBoardDelegate respondsToSelector:@selector(pluginBoardView:clickedItemWithTag:)]) {
        RCPluginBoardItem *item = _allItems[indexPath.row + indexPath.section * self.layout.itemsPerSection];
        [_pluginBoardDelegate pluginBoardView:self clickedItemWithTag:item.tag];
    }
    
}
//返回这个UICollectionView是否可以被选择
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (float) getBoardViewBottonOriginY{
    float gap = (IOS_FSystenVersion < 7.0) ? 64 : 0 ;
    return [UIScreen mainScreen].bounds.size.height - gap;
}

//用于动画效果
- (void)setHidden:(BOOL)hidden {
    CGRect viewRect = self.frame;
    if (hidden) {
        viewRect.origin.y = [self getBoardViewBottonOriginY];
    } else {
        viewRect.origin.y = [self getBoardViewBottonOriginY] - self.frame.size.height;
    }
    [self setFrame:viewRect];
    [super setHidden:hidden];
}

@end
