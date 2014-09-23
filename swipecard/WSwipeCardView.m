//
//  WSwipeCardView.m
//  swipecard
//
//  Created by lixin on 9/13/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import "WSwipeCardView.h"
#import <pop/POP.h>
#import <QuartzCore/QuartzCore.h>
//#import <UIView+AutoLayout/UIView+AutoLayout.h>


CGFloat const SwipeCardItemOffset = 10;
CGFloat const SwipeCardDisappearDistance = 80;
CGFloat const SwipeCardZoomScale = 0.35f;
NSInteger const SwipeCardMaxStackCount = 3;

@interface WSwipeCardView()
@property (nonatomic, strong) NSMutableArray *cardItemViews;
//@property (nonatomic, strong) NSMutableArray *cardConstraints;
@property (nonatomic, weak) UIPanGestureRecognizer *panGesture;
@property (nonatomic, weak) UIView *contentView;
@end

@implementation WSwipeCardView
{
    NSInteger currentTopVisible;
    NSInteger itemCount;
    UIEdgeInsets cardItemInset;
    
    UIView *topView;
    
    CGFloat panBeginConstant;
    BOOL lastMoveToRight;
    NSInteger SwipeCardItemVisibleCount;
}

- (id)init
{
    if (self = [super init]) {
//        self.translatesAutoresizingMaskIntoConstraints = NO;
        SwipeCardItemVisibleCount = SwipeCardMaxStackCount;
        currentTopVisible = -1;
        cardItemInset = UIEdgeInsetsMake(0, 4, 0, 0);
        self.clipsToBounds = YES;
        
        UIView *contentView = [[UIView alloc] init];
        [self addSubview:contentView];
        _contentView = contentView;
//        _contentView.backgroundColor = [UIColor blueColor];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMove:)];
        [self addGestureRecognizer:pan];
        _panGesture = pan;
    }
    return self;
}


- (void)view:(UIView*)view marginLeft:(CGFloat)marginLeft
{
    CGRect f = view.frame;
    f.origin.x = marginLeft;
    view.frame = f;
}

- (void)panMove:(UIPanGestureRecognizer*)recognizer
{
    UIView *currentTopView = [_cardItemViews objectAtIndex:currentTopVisible];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        panBeginConstant = CGRectGetMinX(currentTopView.frame);
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint trans = [recognizer translationInView:self];
        CGFloat offsetScale = fminf(1.0f, fabs(trans.x/SwipeCardDisappearDistance));
        //move the top
        CGFloat standardPos = [self leftOffsetForItem:currentTopVisible];
        BOOL moveToRight = trans.x+panBeginConstant >= standardPos;// leftConstraint.constant - standardPos >= 0;
        if (lastMoveToRight != moveToRight) {
            int toperViewIdx = (currentTopVisible+1)%itemCount;
            UIView *toperView = [_cardItemViews objectAtIndex:toperViewIdx];
            toperView.alpha = 0;
            toperView.transform = CGAffineTransformIdentity;
        }
        lastMoveToRight = moveToRight;
        if (moveToRight) {
            currentTopView.alpha = 1 - offsetScale;
            
            for (int i = 1; i < SwipeCardItemVisibleCount; i ++) {
                int underViewIdx = ((currentTopVisible - i)+itemCount)%itemCount;
                UIView *cardView = _cardItemViews[underViewIdx];
                CGFloat underViewOffset;
                underViewOffset = offsetScale*SwipeCardItemOffset;
                [self view:cardView marginLeft:[self leftOffsetForItem:underViewIdx] + underViewOffset];
            }
            
            currentTopView.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(trans.x, 0),
                                                               CGAffineTransformMakeScale(1+SwipeCardZoomScale*offsetScale, 1+SwipeCardZoomScale*offsetScale));;
            
            //let bottom view appear
            int bottomIdx = ((currentTopVisible - SwipeCardItemVisibleCount)+itemCount)%itemCount;
            UIView *underView = [_cardItemViews objectAtIndex:bottomIdx];
            underView.alpha = offsetScale;
        } else {
            //move under views
            for (int i = 0; i < SwipeCardItemVisibleCount-1; i ++) {
                int underViewIdx = (currentTopVisible-i+itemCount)%itemCount;
                UIView *cardView = _cardItemViews[underViewIdx];
                [self view:cardView marginLeft:[self leftOffsetForItem:underViewIdx] - offsetScale*SwipeCardItemOffset];
            }
            currentTopView.alpha = 1;
            
            //let more top view coming
            int toperViewIdx = (currentTopVisible+1)%itemCount;
            UIView *toperView = [_cardItemViews objectAtIndex:toperViewIdx];
            
            [_contentView bringSubviewToFront:toperView];
            
            toperView.alpha = offsetScale;
            toperView.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(standardPos+SwipeCardDisappearDistance - offsetScale*SwipeCardDisappearDistance, 0),
                                                               CGAffineTransformMakeScale(1+SwipeCardZoomScale*(1-offsetScale), 1+SwipeCardZoomScale*(1-offsetScale)));
        }
        
    } else { //end | cancel
        CGPoint trans = [recognizer translationInView:self];
        CGFloat offsetScale = fminf(1.0f, fabs(trans.x/SwipeCardDisappearDistance));
        CGFloat standardPos = [self leftOffsetForItem:currentTopVisible];
        BOOL moveToRight = trans.x+panBeginConstant >= standardPos;
        
        if (moveToRight) {
            if (offsetScale < 1.0f) {
                //run animation
                NSArray *anims = [self animCardfadeOut:currentTopView];
                POPBasicAnimation *transAnim = anims[0];
                [transAnim setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
                    if (finished) {
                        [_contentView sendSubviewToBack:currentTopView];
                        currentTopView.transform = CGAffineTransformIdentity;
                        [self view:currentTopView marginLeft:0];
                    }
                }];
                POPBasicAnimation *zoomAnim = anims[2];
                [zoomAnim setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
                    if (finished) {
                        currentTopView.transform = CGAffineTransformIdentity;
                    }
                }];
                //move under views
                for (int i = 1; i < SwipeCardItemVisibleCount; i ++) {
                    int underViewIdx = ((currentTopVisible - i)+itemCount)%itemCount;
                    UIView *cardView = _cardItemViews[underViewIdx];
                    POPBasicAnimation *transitionAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
                    transitionAnim.toValue = @([self leftOffsetForItem:underViewIdx] + SwipeCardItemOffset + CGRectGetWidth(cardView.frame)/2);
                    [cardView.layer pop_addAnimation:transitionAnim forKey:@"moveonpos"];
                }
                //
                //let bottom view appear
                {
                    UIView *underView = [_cardItemViews objectAtIndex:((currentTopVisible - SwipeCardItemVisibleCount)+itemCount)%itemCount];
                    POPBasicAnimation *alphaAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
                    alphaAnim.toValue = @(1);
                    [underView pop_addAnimation:alphaAnim forKey:@"fadein"];
                }
            } else {
                [_contentView sendSubviewToBack:currentTopView];
                currentTopView.transform = CGAffineTransformIdentity;
                [self view:currentTopView marginLeft:0];
//                currentLeftConstraint.constant = 0;
            }
            currentTopVisible = (currentTopVisible - 1 + itemCount)%itemCount;
            
        } else {
            if (offsetScale < 1) {
                for (int i = 0; i < SwipeCardItemVisibleCount-1; i ++) {
                    int underViewIdx = (currentTopVisible-i+itemCount)%itemCount;
                    UIView *cardView = _cardItemViews[underViewIdx];
                    POPBasicAnimation *transitionAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
                    transitionAnim.toValue = @([self leftOffsetForItem:underViewIdx] - SwipeCardItemOffset + CGRectGetWidth(cardView.frame)/2);
                    [cardView.layer pop_addAnimation:transitionAnim forKey:@"moveonpos"];
                }
                currentTopView.alpha = 1;
                int toperViewIdx = (currentTopVisible+1)%itemCount;
                UIView *toperView = [_cardItemViews objectAtIndex:toperViewIdx];

                [self animCardfadein:toperView];
            } else {
                UIView *toperView = [_cardItemViews objectAtIndex:(currentTopVisible+1)%itemCount];
                toperView.transform = CGAffineTransformIdentity;
                [self view:toperView marginLeft:standardPos];
            }
            currentTopVisible = (currentTopVisible + 1 + itemCount)%itemCount;
        }
    }
}

- (NSArray*)animCardfadeOut:(UIView*)cardView
{
    CGFloat standardPos = [self leftOffsetForItem:currentTopVisible];
    POPBasicAnimation *transitionAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    transitionAnim.toValue = @(standardPos+SwipeCardDisappearDistance+CGRectGetWidth(cardView.frame)/2);
    [cardView.layer pop_addAnimation:transitionAnim forKey:@"moveright"];
    
    POPBasicAnimation *alphaAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    alphaAnim.toValue = @(0);
    [cardView pop_addAnimation:alphaAnim forKey:@"fadeout"];

    POPBasicAnimation *zoomAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    zoomAnim.toValue = [NSValue valueWithCGSize:CGSizeMake(1+SwipeCardZoomScale, 1+SwipeCardZoomScale)];
    [cardView.layer pop_addAnimation:zoomAnim forKey:@"zoomout"];
    
    return @[transitionAnim, alphaAnim, zoomAnim];
}

- (NSArray*)animCardfadein:(UIView*)cardView
{
    CGFloat standardPos = [self leftOffsetForItem:currentTopVisible];

    POPBasicAnimation *alphaAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    alphaAnim.toValue = @(1);
    [cardView pop_addAnimation:alphaAnim forKey:@"fadein"];

    //Really trick here.
    //
    CGFloat oldX = cardView.frame.origin.x;
    cardView.transform = CGAffineTransformIdentity;
    CGRect f = cardView.frame;
    f.origin.x = oldX;
    cardView.frame = f;
    
    POPBasicAnimation *transitionAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
    transitionAnim.toValue = @(standardPos + CGRectGetWidth(_contentView.frame)/2);
    [cardView.layer pop_addAnimation:transitionAnim forKey:@"moveleft"];
    
    return nil;
//    return @[transitionAnim, alphaAnim, zoomAnim];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self adjustContentFrame];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self adjustContentFrame];
}

- (BOOL)isExclusiveTouch
{
    return YES;
}

- (void)adjustContentFrame
{
    _contentView.frame = UIEdgeInsetsInsetRect(self.bounds, cardItemInset);
    for (int i = 0; i < _cardItemViews.count; i ++) {
        UIView *card = _cardItemViews[i];
        card.frame = _contentView.bounds;
        [self view:card marginLeft:[self leftOffsetForItem:i]];
    }
}

- (void)reloadData
{
    if (self.delegate) {
        itemCount = [self.delegate numberOfItemInSwipeCard:self];
        for (UIView *cardItemView in self.cardItemViews) {
            [cardItemView removeFromSuperview];
        }
//        [_cardConstraints removeAllObjects];
        if (itemCount <= 0) {
            return;
        }
        if (itemCount == 1) {
            self.panGesture.enabled = NO;
        }
        SwipeCardItemVisibleCount = MIN(SwipeCardMaxStackCount, itemCount-1);
        if (SwipeCardItemVisibleCount < 1) {
            SwipeCardItemVisibleCount = 1;
        }
        currentTopVisible = itemCount - 1;
        _cardItemViews = [[NSMutableArray alloc] initWithCapacity:itemCount];
        for (int i = 0; i < itemCount; i ++) {
            UIView *card = [self.delegate itemInSwipeCard:self atIndex:i];
            [_contentView addSubview:card];
            [_cardItemViews addObject:card];
            
            card.alpha = [self alphaForItem:i];
        }
        [self adjustContentFrame];
        topView = [_cardItemViews objectAtIndex:currentTopVisible];
    }
}


- (CGFloat)leftOffsetForItem:(NSInteger)itemIndex
{
    CGFloat topItemLeft = SwipeCardItemOffset*(SwipeCardItemVisibleCount-1);
    if (itemIndex == currentTopVisible) {
        return topItemLeft;
    } else {
        int subCount = (currentTopVisible - itemIndex + itemCount)%itemCount;
        CGFloat itemPlace = fmaxf(0, topItemLeft - SwipeCardItemOffset*subCount);
        return itemPlace;
    }
}

- (CGFloat)alphaForItem:(NSInteger)itemIndex
{
    if (itemCount == 1) {
        return 1;
    }
    if (itemIndex > currentTopVisible) {
        return 0;
    } else if (itemIndex >= itemCount - SwipeCardItemVisibleCount) {
        return 1;
    } else {
        return 0;
    }
}

@end
