//
//  WXClient.m
//  RACWeather
//
//  Created by 我叫MT on 17/2/24.
//  Copyright © 2017年 Pinksnow. All rights reserved.
//

#import "WXClient.h"

@implementation WXClient

-(instancetype)init
{
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

/*
 1.返回信号。请记住，这将不会执行，直到这个信号被订阅。 - fetchJSONFromURL：创建一个对象给其他方法和对象使用；这种行为有时也被称为工厂模式。
 2.创建一个NSURLSessionDataTask（在iOS7中加入）从URL取数据。你会在以后添加的数据解析。
 3.一旦订阅了信号，启动网络请求。
 4.创建并返回RACDisposable对象，它处理当信号摧毁时的清理工作。
 5.增加了一个“side effect”，以记录发生的任何错误。side effect不订阅信号，相反，他们返回被连接到方法链的信号。你只需添加一个side effect来记录错误。
 */
/*
  Handle retrieved data中的代码替换
 1.当JSON数据存在并且没有错误，发送给订阅者序列化后的JSON数组或字典。
 2.在任一情况下如果有一个错误，通知订阅者。
 3.无论该请求成功还是失败，通知订阅者请求已经完成。

 */

-(RACSignal *)fetchJSONFromURL:(NSURL *)url
{
  //  NSLog(@"%@",url.absoluteString);
    //1
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //2
       NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          //handle retrieved data
           if (!error) {
               NSError *jsonError = nil;
               id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
               if (!jsonError) {
                   //1.
                   [subscriber sendNext:json];
               }else{
                   //2.
                   [subscriber sendError:jsonError];
               }
           }else{
               //2.
               [subscriber sendError:error];
           }
           //3.
           [subscriber sendCompleted];
       }];
        //3
        [dataTask resume];
        //4
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }]doError:^(NSError *error) {
        //5
        NSLog(@"%@",error);
    }];
}


//获取当前状况
/*
 1.使用CLLocationCoordinate2D对象的经纬度数据来格式化URL。
 2.用你刚刚建立的创建信号的方法。由于返回值是一个信号，你可以调用其他ReactiveCocoa的方法。 在这里，您将返回值映射到一个不同的值 – 一个NSDictionary实例。
 3.使用MTLJSONAdapter来转换JSON到WXCondition对象 – 使用MTLJSONSerializing协议创建的WXCondition。
 */
-(RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate
{   // 1
    NSString *urlString = [NSString stringWithFormat:@"http://samples.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=f761dc2d5a52a5039a6c44e6fb248cc8",coordinate.latitude,coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    //2
    return [[self fetchJSONFromURL:url]map:^(NSDictionary *json) {
        //3
        return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
    }];
}

//获取逐时预报
/*
 1.再次使用-fetchJSONFromUR方法，映射JSON。注意：重复使用该方法节省了多少代码！
 2.使用JSON的”list”key创建RACSequence。 RACSequences让你对列表进行ReactiveCocoa操作。
 3.映射新的对象列表。调用-map：方法，针对列表中的每个对象，返回新对象的列表。
 4.再次使用MTLJSONAdapter来转换JSON到WXCondition对象。
 */
-(RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"http://samples.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=b1b15e88fa797225412429c1c50c122a1",coordinate.latitude,coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"%@",url);
    //1
    return [[self fetchJSONFromURL:url]map:^(NSDictionary *json) {
        //2
        RACSequence *list = [json[@"list"] rac_sequence];
        //3
        return [[list map:^(NSDictionary *item) {
            //4
            return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
            //5
        }]array];
    }];
}

-(RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"http://samples.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&appid=b1b15e88fa797225412429c1c50c122a1",coordinate.latitude,coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    return [[self fetchJSONFromURL:url]map:^(NSDictionary *json){
        RACSequence *list = [json[@"list"] rac_sequence];
        return [list map:^(NSDictionary *item) {
            return [[MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:json error:nil]array];
        }];
    }];
}



@end
