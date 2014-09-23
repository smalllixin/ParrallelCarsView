//
//  WSwipeCardView.h
//  swipecard
//
//  Created by lixin on 9/13/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WSwipeCardView;

@protocol WSwipeCardViewDelegate<NSObject>
@required
- (NSInteger)numberOfItemInSwipeCard:(WSwipeCardView*)cardView;
- (UIView*)itemInSwipeCard:(WSwipeCardView*)cardView atIndex:(NSInteger)atIndex; //(5 items eg.) TOP 4 3 2 1 0 BOTTOM
@end

@interface WSwipeCardView : UIView

@property (nonatomic, weak) id<WSwipeCardViewDelegate> delegate;

- (void)reloadData;
@end
