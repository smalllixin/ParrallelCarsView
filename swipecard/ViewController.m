//
//  ViewController.m
//  swipecard
//
//  Created by lixin on 9/13/14.
//  Copyright (c) 2014 lxtap. All rights reserved.
//

#import "ViewController.h"
#import <UIView+AutoLayout.h>
#import <UIColor+MLPFlatColors.h>
//#import "WSwipeCardView.h"
#import "WParrallelCardsView.h"
@interface ViewController ()<WParrallelCardsViewDelegate>

//@property (nonatomic, weak) WSwipeCardView *cardView;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIView *block;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _scrollView = [UIScrollView newAutoLayoutView];
    [self.view addSubview:_scrollView];
    [_scrollView autoPinEdgesToSuperviewEdges];
    
//    WSwipeCardView *cardView = [WSwipeCardView newAutoLayoutView];
//    cardView.backgroundColor = [UIColor redColor];
//    [self.scrollView addSubview:cardView];
//    [cardView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//    [cardView autoPinEdgeToSuperviewEdge:ALEdgeRight];
//    [cardView autoSetDimension:ALDimensionWidth toSize:320];
//    [cardView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:50];
//    [cardView autoSetDimension:ALDimensionHeight toSize:100];
    
//    _cardView = cardView;
//    _cardView.backgroundColor = [UIColor redColor];
//    _cardView.hidden = YES;
//    _cardView.delegate = self;
////    _cardView.backgroundColor = [UIColor flatDarkBlackColor];
//    [_cardView reloadData];
    
    
    WParrallelCardsView *cs = [WParrallelCardsView newAutoLayoutView];
    [self.scrollView addSubview:cs];
    [cs autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:300];
    [cs autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [cs autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [cs autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:_scrollView];
//    [cs autoSetDimension:ALDimensionWidth toSize:320];
    [cs autoSetDimension:ALDimensionHeight toSize:100];
    [cs autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:500];
    cs.delegate = self;
    [cs reloadData];
    [self.view layoutIfNeeded];
    
    
    UIView *bb = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 200, 200)];
//    [self.view addSubview:bb];
    bb.backgroundColor = [UIColor flatDarkPurpleColor];
    UIView *block = [[UIView alloc] initWithFrame:CGRectMake(50,50, 200, 200)];
    [self.view addSubview:block];
    block.backgroundColor = [UIColor flatBlackColor];
    UILabel *label = [UILabel newAutoLayoutView];
    label.text = @"HA 123";
    [block addSubview:label];
    [label autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [label autoAlignAxisToSuperviewAxis:ALAxisVertical];

//    block.layer.shadowColor = [UIColor blackColor].CGColor;
//    block.layer.shadowOpacity = 1;
//    block.layer.shadowRadius = 5;
    CATransform3D t = CATransform3DIdentity;
//    t.m34 = -0.1;//-1.0/500.0;
//    t = CATransform3DScale(t, 0.5, 0.5, 0);
//    t = CATransform3DTranslate(t, 10, 0, -20);
    block.layer.transform = t;
    _block = block;
    
//    _timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
}

- (void)timerTick:(NSTimer*)tm
{
    static int i = 0;
    CATransform3D t = CATransform3DIdentity;
    t.m34 = -1.0/500.0;
    i++;
    //    t = CATransform3DScale(t, 0.5, 0.5, 0);
    t = CATransform3DTranslate(t, 10, 0, ((i++)%10)*(-20));
    
    t = CATransform3DRotate(t, 45.0f * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
//    _block.layer.opacity = (i%10)*1.0f/10*1.0f;
    _block.layer.transform = t;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfItemInCardsShowView:(WParrallelCardsView*)cardsView
{
    return 6;
}

- (UIView*)itemInCardsShowView:(WParrallelCardsView*)cardsView atIndex:(NSInteger)atIndex
{
    UIView *pureColorView = [cardsView cachedViewAtIndex:atIndex];
    if (pureColorView == nil) {
        pureColorView = [UIView newAutoLayoutView];
        UILabel *descrLabel = [UILabel newAutoLayoutView];
        descrLabel.tag = 2;
        [pureColorView addSubview:descrLabel];
        [descrLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 5, 0, 0) excludingEdge:ALEdgeRight];
    }
    UILabel *descrLabel = (UILabel*)[pureColorView viewWithTag:2];
    switch (atIndex) {
        case 0:
            pureColorView.backgroundColor = [UIColor flatDarkPurpleColor];
            break;
        case 1:
            pureColorView.backgroundColor = [UIColor flatDarkGreenColor];
            break;
        case 2:
            pureColorView.backgroundColor = [UIColor flatDarkBlueColor];
            break;
        case 3:
            pureColorView.backgroundColor = [UIColor flatDarkOrangeColor];
            break;
        case 4:
            pureColorView.backgroundColor = [UIColor flatDarkYellowColor];
            break;
        default:
            pureColorView.backgroundColor = [UIColor randomFlatColor];
            break;
    }
    
    descrLabel.text = [NSString stringWithFormat:@"%ld", atIndex];
    descrLabel.textColor = [UIColor whiteColor];
    
    return pureColorView;
}

//- (NSInteger)numberOfItemInSwipeCard:(WSwipeCardView*)cardView {
//    return 5;
//}
//
//- (UIView*)itemInSwipeCard:(WSwipeCardView*)cardView atIndex:(NSInteger)atIndex {
//    UIView *pureColorView = [UIView new];
//    switch (atIndex) {
//        case 0:
//            pureColorView.backgroundColor = [UIColor flatDarkPurpleColor];
//            break;
//        case 1:
//            pureColorView.backgroundColor = [UIColor flatDarkGreenColor];
//            break;
//        case 2:
//            pureColorView.backgroundColor = [UIColor flatDarkBlueColor];
//            break;
//        case 3:
//            pureColorView.backgroundColor = [UIColor flatDarkOrangeColor];
//            break;
//        case 4:
//            pureColorView.backgroundColor = [UIColor flatDarkYellowColor];
//            break;
//        default:
//            pureColorView.backgroundColor = [UIColor randomFlatColor];
//            break;
//    }
//    
//    UILabel *descrLabel = [UILabel newAutoLayoutView];
//    descrLabel.text = [NSString stringWithFormat:@"%d", atIndex];
//    descrLabel.textColor = [UIColor whiteColor];
//    [pureColorView addSubview:descrLabel];
//    [descrLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 5, 0, 0) excludingEdge:ALEdgeRight];
//    return pureColorView;
//}

@end
