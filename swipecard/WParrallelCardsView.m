//
//  WCardsShowView.m
//  swipecard
//
//  Created by lixin on 9/18/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import "WParrallelCardsView.h"
#include <math.h>
#import <QuartzCore/QuartzCore.h>
#import <UIView+AutoLayout.h>

static CGFloat const MARGIN_LEFT = 44;
static CGFloat const STACK_HOR_OFFSET = 26;
static CGFloat const DEEP_DISTANCE = 40;
static CGFloat const perspective = -1.0/500.0;

@interface WParrallelCardsView()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, strong) NSMutableArray *contentLayers;
@property (nonatomic, assign) NSInteger cardCount;
@property (nonatomic, weak) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger currentTopVisibleCard;
@end

struct WCardsShowViewState
{
    CGFloat xMove;
    CGFloat zMove;
    CGFloat opacity;
};

@implementation WParrallelCardsView
{
    CGRect vFrame;
    NSInteger visibleCardCount;
}

#pragma mark - Initialization
- (id)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor blackColor];
        UIView *contentView = [UIView newAutoLayoutView];
        [self addSubview:contentView];
        _contentView = contentView;
        [_contentView autoPinEdgesToSuperviewEdges];
        _cardCount = 0;
        
        _contentLayers = [NSMutableArray array];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMove:)];
        [self addGestureRecognizer:pan];
        _panGesture = pan;
        
        _panGesture.delegate = self;
        
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    vFrame = self.frame;
    [self makeCardsStackEffect];
}

#pragma mark - Public
- (void)reloadData
{
    if (self.delegate) {
        _cardCount = [self.delegate numberOfItemInCardsShowView:self];
        visibleCardCount = _cardCount - 1;
        if (visibleCardCount > 3) {
            visibleCardCount = 3;
        } else if (visibleCardCount < 1) {
            visibleCardCount = 1;
        }
        for (UIView *card in _contentView.subviews) {
            [card removeFromSuperview];
        }
        [_contentLayers removeAllObjects];
        
        for (int i = 0; i < _cardCount; i ++) {
            UIView *card = [self.delegate itemInCardsShowView:self atIndex:i];
            [_contentView addSubview:card];
            [_contentLayers addObject:card.layer];
            [card autoPinEdgesToSuperviewEdges];
        }
        
        _currentTopVisibleCard = _cardCount - 1;
        [self makeCardsStackEffect];
    }
}

#pragma mark - Effect Handle
/**
 1. currentView 向任何方向滑动，会引起自身的变化，可以设置移动范围对其scale的影响
 2. currentView 之下的view
 
 每一层的view都有他的位移变化 scale变化，alpha变化范围
 每一层的view都有他的dock位置
 pan gesture在x alxis方向会影响
 
 让所有view x offset 都是相等的
 A
   B
     C <- current
 zOffset 在under currentIndex是均匀的， 在>= currentIndex是增加的
 
 这样均匀控制x,不均匀控制z，可以简化计算
 */

- (CGFloat)viewPosXInStack:(NSInteger)stackIdx currentTop:(NSInteger)currentTop totalStackCount:(NSInteger)count
{
    if (stackIdx < currentTop) {
        
        CGFloat standardXMove = MARGIN_LEFT - STACK_HOR_OFFSET*(currentTop-stackIdx);
        return standardXMove;
    }
    else if (stackIdx == currentTop) {
        return MARGIN_LEFT;
    }
    else// (stackIdx > currentTop) {
    {
        return CGRectGetWidth(self.frame);
    }
}

- (CGFloat)viewPosZInStack:(NSInteger)stackIdx currentTop:(NSInteger)currentTop totalStackCount:(NSInteger)count
{
    if (stackIdx < currentTop) {
        return -DEEP_DISTANCE - (currentTop-stackIdx)*DEEP_DISTANCE;
//        return -DEEP_DISTANCE*(count) + stackIdx*DEEP_DISTANCE;
    }
    else if (stackIdx == currentTop) {
        return -DEEP_DISTANCE;
    }
    else// (stackIdx > currentTop) {
    {
        return DEEP_DISTANCE*5;
    }
}

/*
 moveScale [-1, 0, 1],  -1 means move left,  0 ,  1 means move right
 */
- (struct WCardsShowViewState)viewStateInStack:(NSInteger)stackIdx currentTop:(NSInteger)currentTop totalStackCount:(NSInteger)count moveScale:(CGFloat)moveScale
{
    struct WCardsShowViewState s;
    
//    int visibleCount = count - stackIdx;
    const CGFloat DISAPPEAR_ACCELERATE_FACTOR = 1.5f;
    
    CGFloat standardXMove = [self viewPosXInStack:stackIdx currentTop:currentTop totalStackCount:count];
    if (moveScale == 0) {
        s.xMove = standardXMove;
    } else if (moveScale > 0) {
        CGFloat topperX = [self viewPosXInStack:stackIdx+1 currentTop:currentTop totalStackCount:count];
        s.xMove = standardXMove + (topperX - standardXMove)*moveScale;
    } else if (moveScale < 0) {
        CGFloat underX = [self viewPosXInStack:stackIdx-1 currentTop:currentTop totalStackCount:count];
        s.xMove = standardXMove + ABS(underX - standardXMove)*moveScale;
    }
    
    CGFloat standardZMove = [self viewPosZInStack:stackIdx currentTop:currentTop totalStackCount:count];
    if (moveScale == 0) {
        s.zMove = standardZMove;
    } else if (moveScale > 0) {
        CGFloat topperZ = [self viewPosZInStack:stackIdx+1 currentTop:currentTop totalStackCount:count];
        s.zMove = standardZMove + ABS(topperZ - standardZMove)*moveScale*DISAPPEAR_ACCELERATE_FACTOR; //*2 accelerate scale speed
    } else {
        CGFloat underZ = [self viewPosZInStack:stackIdx-1 currentTop:currentTop totalStackCount:count];
        s.zMove = standardZMove + ABS(underZ - standardZMove)*moveScale;
    }

    if (stackIdx < currentTop) {
        s.opacity = 1;
    } else if (stackIdx == currentTop) {
        if (moveScale < 0) {
            s.opacity = 1;
        } else {
            s.opacity = (1-moveScale*DISAPPEAR_ACCELERATE_FACTOR) * 1;
        }
    } else {//stackIdx > currentTop
        if (moveScale < 0) {
            s.opacity = ABS(moveScale * DISAPPEAR_ACCELERATE_FACTOR * 1);
        } else {
            s.opacity = 0;
        }
    }
    
    return s;
}

- (void)makeCardsStackEffect
{
    if (CGRectIsEmpty(self.frame)) {
        return;
    }
    for (int i = 0; i < _cardCount; i ++) {
        CALayer *layer = [_contentLayers objectAtIndex:i];
        struct WCardsShowViewState s = [self viewStateInStack:i currentTop:_cardCount-1 totalStackCount:_cardCount moveScale:0];
        layer.opacity = s.opacity;
        layer.transform = [self buildTransformWithX:s.xMove zMove:s.zMove];
    }
}

- (CATransform3D)buildTransformWithX:(CGFloat)xMove zMove:(CGFloat)zMove
{
    CATransform3D t = CATransform3DIdentity;
    t.m34 = perspective;
    t = CATransform3DTranslate(t, xMove, 0, zMove);
    t = CATransform3DRotate(t, 10*M_PI/180, 0, 1, 0);
    return t;
}

#pragma mark - Gesture Event
- (void)panMove:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
//        [self logLayerState];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint trans = [recognizer translationInView:self];
        
        static CGFloat const SwipeDisappearScale = 0.6f;
        CGFloat width = CGRectGetWidth(self.frame);
        CGFloat dispearDistance = width*SwipeDisappearScale;// * SwipeDisappearScale;
        CGFloat transScale = MAX(-1, MIN(1, trans.x / dispearDistance));
        for (int i = 0; i < _cardCount; i ++) {
            struct WCardsShowViewState s = [self viewStateInStack:i currentTop:_currentTopVisibleCard totalStackCount:_cardCount moveScale:transScale];
            CALayer *viewLayer = _contentLayers[i];
            viewLayer.opacity = s.opacity;
            viewLayer.transform = [self buildTransformWithX:s.xMove zMove:s.zMove];
        }
    } else {
        // end or cancel
        CGPoint trans = [recognizer translationInView:self];

        BOOL moveDirection;
        if (trans.x > 0) {
            moveDirection = 1;
        } else if (trans.x < 0) {
            moveDirection = -1;
        } else {
            return;
        }
        
        _currentTopVisibleCard = MIN(MAX(_currentTopVisibleCard-moveDirection, 0), _cardCount-1);
        
        for (int i = 0; i < _cardCount; i ++) {
            CALayer *viewLayer = _contentLayers[i];
            struct WCardsShowViewState s = [self viewStateInStack:i currentTop:_currentTopVisibleCard totalStackCount:_cardCount moveScale:0];
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{
                viewLayer.opacity = s.opacity;
                viewLayer.transform = [self buildTransformWithX:s.xMove zMove:s.zMove];
            } completion:^(BOOL finished) {
                if (finished) {
                }
            }];
        }
//        NSLog(@"AFTER----");
//        [self logLayerState];
    }
}

- (void)logLayerState
{
    NSLog(@"current:%d", _currentTopVisibleCard);
    for (int i = 0; i < _cardCount; i ++) {
        struct WCardsShowViewState s = [self viewStateInStack:i currentTop:_currentTopVisibleCard totalStackCount:_cardCount moveScale:0];
        NSLog(@"s%d  x:%f  z:%f", i, s.xMove, s.zMove);
    }
}

#pragma mark - Gesture Delegate
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint trans = [gestureRecognizer translationInView:self];
//    NSLog(@"should x:%f y:%f", trans.x, trans.y);
    if (fabsf(trans.y) > fabsf(trans.x)) {
        return NO;
    } else {
        return YES;
    }
}
@end
