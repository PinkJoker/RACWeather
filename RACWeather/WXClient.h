//
//  WXClient.h
//  RACWeather
//
//  Created by 我叫MT on 17/2/24.
//  Copyright © 2017年 Pinksnow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXDailyForecast.h"
#import "WXCondition.h"
@interface WXClient : NSObject<MTLJSONSerializing>
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *humidity;
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *tempHigh;
@property (nonatomic, strong) NSNumber *tempLow;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSDate *sunrise;
@property (nonatomic, strong) NSDate *sunset;
@property (nonatomic, strong) NSString *conditionDescription;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSNumber *windBearing;
@property (nonatomic, strong) NSNumber *windSpeed;
@property (nonatomic, strong) NSString *icon;


-(RACSignal *)fetchJSONFromURL:(NSURL *)url;
-(RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D )coordinate;
-(RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate;
-(RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D )coordinate;

@property(nonatomic, strong) NSURLSession *session;
@end
