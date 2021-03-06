//
//  FFNearbyVC.m
//  SmartMesh
//
//  Created by Rain on 17/12/08.
//  Copyright © 2017年 SmartMesh Foundation All rights reserved.
//

#import "FFNearbyVC.h"
#import "FFChatViewController.h"
#import "FFNearbyPeopleListVC.h"

@interface FFNearbyVC ()<DDYRadarViewDataSource, DDYRadarViewDelegate>

@property (nonatomic, strong) DDYRadarView *radarView;

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation FFNearbyVC

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showRightBarBtnWithTitle:nil img:[UIImage imageNamed:@"icon_discover_changed"]];
    [self.radarView startScanAnimation];
    [self.radarView reloadData];
    [self addObserverActive];
    [self loadNoNetworkData];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBackgroundAlpha:0];
    [self setNavigationBarBottomLineHidden:YES];
    self.navigationController.navigationBar.tintColor  = DDY_White;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:DDY_White};
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setNavigationBackgroundAlpha:1];
    [self setNavigationBarBottomLineHidden:NO];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:DDY_Black};
}

- (DDYRadarView *)radarView {
    if (!_radarView) {
        _radarView = [DDYRadarView radarView];
        _radarView.dataSource = self;
        _radarView.delegate = self;
        _radarView.indicatorStartColor = FF_MAIN_COLOR;
        _radarView.indicatorEndColor = DDYRGBA(220, 190, 50, 0);
        _radarView.indicatorAngle = 240;
        _radarView.indicatorSpeed = 140;
        _radarView.backgroundImage = [UIImage imageNamed:@"radarBg.png"];
        [self.view addSubview:_radarView];
    }
    return _radarView;
}

- (void)rightBtnClick:(DDYButton *)button {
    [self.navigationController pushViewController:[FFNearbyPeopleListVC vc] animated:YES];
}

- (NSInteger)numberOfPointInRadarView:(DDYRadarView *)radarView {
    return self.dataArray.count<8 ? self.dataArray.count : 8;
}

- (UIImage *)radarView:(DDYRadarView *)radarView imageForIndex:(NSInteger)index {
    FFUser *user = self.dataArray[index];
    
    // 保存用户
    FFUser *userLocal = [[FFUserDataBase sharedInstance] getUserWithLocalID:user.localID];
    if (userLocal) {
        userLocal.nickName = user.nickName;
        userLocal.userImage = user.userImage;
    } else {
        userLocal = user;
    }
    [[FFUserDataBase sharedInstance] saveUser:userLocal];
    
    DDYInfoLog(@"发现保存用户：localID:%@\nname:%@\npinyin:%@\ninfo:%@\n",user.localID, user.remarkName, user.pinYin, [NSString ddy_ToJsonStr:user.userInfo]);
    UIImage *avatar = [FFFileManager avatarWithID:user.localID];
    return avatar ? avatar : [FFUser avatarWithRemarkName:user.remarkName];
}

- (void)radarView:(DDYRadarView *)radarView didSelectItemAtIndex:(NSInteger)index {
    FFUser *user = self.dataArray[index];
    FFChatViewController *vc = [FFChatViewController vc];
    [vc chatUID:user.localID chatType:FFChatTypeSingle groupName:user.nickName];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)loadNoNetworkData {
    [[FFMCManager sharedManager] initWithUser:[FFLoginDataBase sharedInstance].loginUser];
    self.dataArray = [NSMutableArray array];
     [self.radarView reloadData];
    __weak __typeof__(self) weakSelf = self;
    [FFMCManager sharedManager].usersArrayChangeBlock = ^(NSMutableArray *onlineUsersArray) {
        weakSelf.dataArray = [NSMutableArray array];
        [weakSelf.dataArray addObjectsFromArray:onlineUsersArray];
        [weakSelf.radarView reloadData];
    };
}

#pragma mark 监听挂起和重新进入程序
#pragma mark 添加监听
- (void)addObserverActive {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark 进入前台
- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (_radarView) [_radarView startScanAnimation];
}

#pragma mark 挂起程序
- (void)applicationWillResignActive:(UIApplication *)application {
    if (_radarView) [self.radarView stopScanAnimation];
}

#pragma mark 状态栏样式
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
