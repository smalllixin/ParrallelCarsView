//
//  WCardsShowView.h
//  swipecard
//
//  Created by lixin on 9/18/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WCardsShowView;
@protocol WCardsShowViewDelegate<NSObject>
@required
- (NSInteger)numberOfItemInCardsShowView:(WCardsShowView*)cardsView;
- (UIView*)itemInCardsShowView:(WCardsShowView*)cardsView atIndex:(NSInteger)atIndex; //(5 items eg.) TOP 4 3 2 1 0 BOTTOM
@end


@interface WCardsShowView : UIView

@property (nonatomic, weak) id<WCardsShowViewDelegate> delegate;

- (void)reloadData;
@end
