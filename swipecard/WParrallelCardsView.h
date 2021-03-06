//
//  WCardsShowView.h
//  swipecard
//
//  Created by lixin on 9/18/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WParrallelCardsView;
@protocol WParrallelCardsViewDelegate<NSObject>
@required
- (NSInteger)numberOfItemInCardsShowView:(WParrallelCardsView*)cardsView;
- (UIView*)itemInCardsShowView:(WParrallelCardsView*)cardsView atIndex:(NSInteger)atIndex; //(5 items eg.) TOP 4 3 2 1 0 BOTTOM
@end


@interface WParrallelCardsView : UIView

@property (nonatomic, weak) id<WParrallelCardsViewDelegate> delegate;

- (void)reloadData;
- (UIView*)cachedViewAtIndex:(NSInteger)atIndex;
@end