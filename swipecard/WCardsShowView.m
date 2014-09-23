//
//  WCardsShowView.m
//  swipecard
//
//  Created by lixin on 9/18/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import "WCardsShowView.h"
#import <QuartzCore/QuartzCore.h>
#import <UIView+AutoLayout.h>
@interface WCardsShowView()
@property (nonatomic, weak) UIView *contentView;
@property (nonatomic, strong) NSMutableArray *contentLayers;
@property (nonatomic, assign) NSInteger cardCount;
@property (nonatomic, weak) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation WCardsShowView
{
    NSInteger currentTopVisible;
    CGRect vFrame;
    CGFloat perspective;
    NSInteger visibleCardCount;
}

- (id)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor blackColor];
        UIView *contentView = [UIView newAutoLayoutView];
        [self addSubview:contentView];
        _contentView = contentView;
        [_contentView autoPinEdgesToSuperviewEdges];
        _cardCount = 0;
        perspective = -1.0/500.0;
        _contentLayers = [NSMutableArray array];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMove:)];
        [self addGestureRecognizer:pan];
        _panGesture = pan;
        
        self.layer.masksToBounds = YES;
//        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    }
    return self;
}

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
        [self makeCardsStackEffect];
    }
}

- (void)tick:(id)tm
{
    static int k = 0;
    CGFloat deepDistance = 20;
    CGFloat horOffset = 20;
    for (int i = 0; i < _cardCount; i ++) {
        UIView *card = [_contentView.subviews objectAtIndex:i];
        
        if (i < _cardCount - visibleCardCount) {
            card.layer.opacity = 0;
        } else {
            CATransform3D t = CATransform3DIdentity;
            t.m34 = perspective;
            t = CATransform3DTranslate(t, 10+ horOffset*i, 0, -deepDistance*_cardCount+i*deepDistance);
            card.layer.transform = t;
            card.layer.opacity = 1;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    vFrame = self.frame;
    [self makeCardsStackEffect];
}

static CGFloat const MARGIN_LEFT = 34;
static CGFloat const STACK_HOR_OFFSET = 26;
static CGFloat const DEEP_DISTANCE = 40;
- (void)makeCardsStackEffect
{
    if (CGRectIsEmpty(self.frame)) {
        return;
    }
    for (int i = 0; i < _cardCount; i ++) {
        CALayer *layer = [_contentLayers objectAtIndex:i];
        
        if (i < _cardCount - visibleCardCount) {
            layer.opacity = 0;
        } else {
            layer.opacity = 1;
        }
        
        CATransform3D t = CATransform3DIdentity;
        t.m34 = perspective;
        NSLog(@"i:%d, %f",i, MARGIN_LEFT - STACK_HOR_OFFSET*(_cardCount-1-i));
        t = CATransform3DTranslate(t, MARGIN_LEFT - STACK_HOR_OFFSET*(_cardCount-1-i), 0, -DEEP_DISTANCE*_cardCount+i*DEEP_DISTANCE);
        layer.transform = t;
    }
}
- (void)moveWall:(CALayer*)wall toDepth:(float)depth {
    NSNumber* value = [NSNumber numberWithFloat:depth];
    [wall setValue:value forKeyPath:@"transform.translation.z"];
}


- (void)panMove:(UIPanGestureRecognizer*)recognizer
{
//    static CGFloat const SwipeDisappearScale = 0.2;
//    UIView *currentTopView = [_contentView.subviews objectAtIndex:currentTopVisible];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
//        panBeginConstant = CGRectGetMinX(currentTopView.frame);
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint trans = [recognizer translationInView:self];
        
        
        
        CGFloat width = CGRectGetWidth(self.frame);
        CGFloat dispearDistance = width;// * SwipeDisappearScale;
        //TBD alpha calculate
        CGFloat transScale = trans.x*5 / dispearDistance;//,1.5);
        //TBD transform
        
        for (int i = _cardCount-visibleCardCount; i < _cardCount; i ++) {
            CALayer *viewLayer = _contentLayers[i];
            CATransform3D t = CATransform3DIdentity;
            t.m34 = perspective;
            t = CATransform3DTranslate(t,
                                       MARGIN_LEFT - STACK_HOR_OFFSET*(_cardCount-1-i) + STACK_HOR_OFFSET*transScale,
                                       0,
                                       -DEEP_DISTANCE*_cardCount+i*DEEP_DISTANCE + DEEP_DISTANCE*transScale);
            viewLayer.transform = t;
        }
        
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
