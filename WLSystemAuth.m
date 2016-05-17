//
//  WLSystemAuth.m
//  Welian
//
//  Created by 好迪 on 16/5/5.
//  Copyright © 2016年 chuansongmen. All rights reserved.
//

#import "WLSystemAuth.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>

#pragma mark - UIAlertView extention
static const void *kAlertViewParamsKey = &kAlertViewParamsKey;

@interface UIAlertView (extention)

@property (nonatomic, strong)id params;

@end

@implementation UIAlertView (extention)

- (void)setParams:(id)params{
    objc_setAssociatedObject(self,kAlertViewParamsKey, params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)params{
    return objc_getAssociatedObject(self, kAlertViewParamsKey);
}

@end

@implementation WLSystemAuth

+ (instancetype)shareInstance{
    static WLSystemAuth *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[WLSystemAuth alloc] init];
    });
    return shared;
}


+ (void)showAlertWithAuthType:(WLSystemAuthType)authType completionHandler:(void (^)(WLSystemAuthStatus status))handler{
    switch (authType) {
        case WLSystemAuthTypeCamera:
            [self showAlertForMediaType:AVMediaTypeVideo completionHandler:handler];
            break;
        case WLSystemAuthTypePhotos:
            [self showAlertForPHAuth: handler];
            break;
        case WLSystemAuthTypeContacts:
            [self showAlertForContactsAuth:handler];
            break;
        case WLSystemAuthTypeLocation:
            [self showAlertForLocationAuth:handler];
            break;
        default:
            DLog(@"暂未支持");
            break;
    }
}

#pragma mark - show alert view
+ (void)showAlertViewWithType:(WLSystemAuthType)authType{
    NSString *Title, *prefs;
    switch (authType) {
        case WLSystemAuthTypeCamera:
            Title = [NSString stringWithFormat:@"请在iPhone的“设置-隐私-相机”选项中，允许【%@】访问您的相机",[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
            prefs = @"prefs:root=Privacy&&path=CAMERA";
            break;
        case WLSystemAuthTypePhotos:
            Title = [NSString stringWithFormat:@"请在iPhone的“设置-隐私-照片”选项中，允许【%@】访问您的照片",[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
            prefs = @"prefs:root=Privacy&&path=PHOTOS";
            break;
        case WLSystemAuthTypeContacts:
            Title = [NSString stringWithFormat:@"请在iPhone的“设置-隐私-通讯录”选项中，允许【%@】访问您的通讯录",[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
            prefs = @"prefs:root=Privacy&&path=CONTACTS";
            break;
        case WLSystemAuthTypeLocation:
            Title = [NSString stringWithFormat:@"请在iPhone的“设置-隐私-定位服务”选项中，允许【%@】访问您的位置",[[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
            prefs = @"prefs:root=LOCATION_SERVICES";
            break;
        default:
            Title = @"未支持";
            break;
    }
    
    [self showAlertViewWithMessage:Title toUrl:prefs];
}

+ (void)showAlertViewWithMessage:(NSString *)message toUrl:(NSString *)prefs{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:[self shareInstance] cancelButtonTitle:@"暂不" otherButtonTitles:@"去设置",nil];
    alertView.params = prefs;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        NSString *prefs = alertView.params;
        NSURL *url = [NSURL URLWithString:prefs];
        if (kIOS8Later) {
           url= [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        }
        if([[UIApplication sharedApplication]canOpenURL:url]){
            [[UIApplication sharedApplication]openURL:url];
        }
    }
}

#pragma mark - private Method
// 摄像头 相机
+ (void)showAlertForMediaType:(NSString *)mediaType completionHandler:(void (^)(WLSystemAuthStatus status))handler{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                if (granted) {
                    handler(WLSystemAuthStatusAuthorized);
                }
                else{
                    handler(WLSystemAuthStatusUnknownError);
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
            handler(WLSystemAuthStatusAuthorized);
            break;
        case AVAuthorizationStatusRestricted:
            NSLog(@"受限，有可能开启了访问限制");
        case AVAuthorizationStatusDenied:
            NSLog(@"访问受限");
            [self showAlertViewWithType:WLSystemAuthTypeCamera];
            handler(WLSystemAuthStatusUnknownError);
            break;
    }
}

// 照片
+ (void)showAlertForPHAuth:(void (^)(WLSystemAuthStatus))handler{
#ifdef __IPHONE_8_0
    if ([UIDevice currentDevice].systemVersion.doubleValue > 8.0f) {
        PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
        switch (authorizationStatus) {
            case PHAuthorizationStatusNotDetermined:{
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    status == PHAuthorizationStatusAuthorized?handler(WLSystemAuthStatusAuthorized):(void)NULL;
                }];
                break;
            }
            case PHAuthorizationStatusAuthorized:
                handler(WLSystemAuthStatusAuthorized);
                break;
            case PHAuthorizationStatusRestricted:
            case PHAuthorizationStatusDenied:
                [self showAlertViewWithType:WLSystemAuthTypePhotos];
                handler(WLSystemAuthStatusUnknownError);
                break;
        }
    } else {
        ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
        switch (authorizationStatus) {
            case ALAuthorizationStatusNotDetermined:{
                handler(WLSystemAuthStatusOther);
                break;
            }
            case ALAuthorizationStatusAuthorized:
                handler(WLSystemAuthStatusAuthorized);
                break;
            case ALAuthorizationStatusRestricted:
            case ALAuthorizationStatusDenied:
                [self showAlertViewWithType:WLSystemAuthTypePhotos];
                handler(WLSystemAuthStatusUnknownError);
                break;
        }
    }
#else
    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
    switch (authorizationStatus) {
        case ALAuthorizationStatusNotDetermined:{
            handler(WLSystemAuthStatusOther);
            break;
        }
        case ALAuthorizationStatusAuthorized:
            handler(WLSystemAuthStatusAuthorized);
            break;
        case ALAuthorizationStatusRestricted:
        case ALAuthorizationStatusDenied:
            [self showAlertViewWithType:WLSystemAuthTypePhotos];
            handler(WLSystemAuthStatusUnknownError);
            break;
    }
#endif
}

// 通讯录
+ (void)showAlertForContactsAuth:(void (^)(WLSystemAuthStatus))handler{
//    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];

    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    switch (status) {
        case kABAuthorizationStatusNotDetermined:{
            ABAddressBookRef addressBook = NULL;
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    handler(WLSystemAuthStatusAuthorized);
                }
                else{
                    handler(WLSystemAuthStatusUnknownError);
                }
            });
        }
            break;
        case kABAuthorizationStatusAuthorized:
            handler(WLSystemAuthStatusAuthorized);
            break;
        case kABAuthorizationStatusRestricted:
        case kABAuthorizationStatusDenied:
            [self showAlertViewWithType:WLSystemAuthTypeContacts];
            handler(WLSystemAuthStatusUnknownError);
            break;
       
    }
}

// 位置
+ (void)showAlertForLocationAuth:(void (^)(WLSystemAuthStatus))handler{
     CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            handler(WLSystemAuthStatusOther);
        }
            break;
        case kCLAuthorizationStatusAuthorized:
//        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (handler) {
                handler(WLSystemAuthStatusAuthorized);
            }
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self showAlertViewWithType:WLSystemAuthTypeLocation];
            if (handler) {
                handler(WLSystemAuthStatusUnknownError);
            }
            break;
    }
}

@end



