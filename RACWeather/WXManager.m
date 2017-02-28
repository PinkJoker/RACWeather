//
//  WXManager.m
//  RACWeather
//
//  Created by 我叫MT on 17/2/24.
//  Copyright © 2017年 Pinksnow. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
@interface WXManager ()
/*
 
 1.声明你在公共接口中添加的相同的属性，但是这一次把他们定义为可读写，因此您可以在后台更改他们。
 2.为查找定位和数据抓取声明一些私有变量。
 */
// 1
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

// 2
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;

@end
@implementation WXManager


//单利
+(instancetype)shareManager{
    static id _shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareManager = [[self alloc]init];
    });
    return _shareManager;
}
//使用RAC观察和反应天气温度等的变化
/*
 1.创建一个位置管理器，并设置它的delegate为self。
 2.为管理器创建WXClient对象。这里处理所有的网络请求和数据分析，这是关注点分离的最佳实践。
 3.管理器使用一个返回信号的ReactiveCocoa脚本来观察自身的currentLocation。这与KVO类似，但更为强大。
 4.为了继续执行方法链，currentLocation必须不为nil。
 5.- flattenMap：非常类似于-map：，但不是映射每一个值，它把数据变得扁平，并返回包含三个信号中的一个对象。通过这种方式，你可以考虑将三个进程作为单个工作单元。
 6.将信号传递给主线程上的观察者。
 7.这不是很好的做法，在你的模型中进行UI交互，但出于演示的目的，每当发生错误时，会显示一个banner。
 */

-(instancetype)init
{
    if (self = [super init]) {
        //1
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
        [_locationManager requestWhenInUseAuthorization];
        //2
        _client = [[WXClient alloc]init];
        //3
        [[[[RACObserve(self, currentLocation)
            //4
            ignore:nil]flattenMap:^(CLLocation *newLocation){
            //5 管理并订阅所有的标志今日  当前 和小时 三个实践的位置变化升级
            return [RACSignal merge:@[
                                      [self updateDailyForecast],
                                      [self updateCurrentConditions],
                                      [self updateHourlyForecast]
                                      ]];
            //6
                    }]deliverOn:[RACScheduler mainThreadScheduler]]subscribeError:^(NSError *error) {
                        //7
                        [TSMessage showNotificationWithTitle:@"Error" subtitle:@"There was a problem" type:TSMessageNotificationTypeError];
                    }];
    }
    return self;
}

//查找当前位置
/*
 1.忽略第一个位置更新，因为它一般是缓存值。
 2.一旦你获得一定精度的位置，停止进一步的更新。
 3.设置currentLocation，将触发您之前在init中设置的RACObservable。
 */
-(void)findCurrentLocation
{
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    //1
    if (self.isFirstUpdate) {
        self.isFirstUpdate  = NO;
        return;
    }
    CLLocation *location = [locations lastObject];
    //2.
    if (location.horizontalAccuracy > 0) {
        //3
        self.currentLocation = location;
        [self.locationManager startUpdatingLocation];
    }
}









- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}
@end
