---
title: iOS系统授权及跳转设置页面引导
date: 2016-05-04 19:46:20
tags: iOS
---
## 相机摄像头的授权
部分代码

```
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
```
##照片授权
```
#ifdef __IPHONE_8_0
    if (kIOS8Later) {
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
```
##位置授权
```
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
```
##通讯录授权
```
// iOS8 以上待定
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
```

## 跳转到设置
引导用户去打开 `在 URL Types 添加 一个叫 prefs 的 URL Schemes`

* iOS 系统功能的 URL 汇总列表：

```
蜂窝网络：prefs:root=MOBILE_DATA_SETTINGS_ID
VPN — prefs:root=General&path=Network/VPN
Wi-Fi：prefs:root=WIFI
定位服务：prefs:root=LOCATION_SERVICES
个人热点：prefs:root=INTERNET_TETHERING
关于本机：prefs:root=General&path=About
辅助功能：prefs:root=General&path=ACCESSIBILITY
飞行模式：prefs:root=AIRPLANE_MODE
锁定：prefs:root=General&path=AUTOLOCK
亮度：prefs:root=Brightness
蓝牙：prefs:root=General&path=Bluetooth
时间设置：prefs:root=General&path=DATE_AND_TIME
FaceTime：prefs:root=FACETIME
设置：prefs:root=General
键盘设置：prefs:root=General&path=Keyboard
iCloud：prefs:root=CASTLE
iCloud备份：prefs:root=CASTLE&path=STORAGE_AND_BACKUP
语言：prefs:root=General&path=INTERNATIONAL
定位：prefs:root=LOCATION_SERVICES
音乐：prefs:root=MUSIC
相机：prefs:root=Privacy&&path=CAMERA
通讯录: prefs:root=Privacy&path=CONTACTS
Music Equalizer — prefs:root=MUSIC&path=EQ
Music Volume Limit — prefs:root=MUSIC&path=VolumeLimit
Network — prefs:root=General&path=Network
Nike + iPod — prefs:root=NIKE_PLUS_IPOD
Notes — prefs:root=NOTES
Notification — prefs:root=NOTIFICATIONS_ID
Phone — prefs:root=Phone
Photos — prefs:root=PHOTOS
Profile — prefs:root=General&path=ManagedConfigurationList
Reset — prefs:root=General&path=Reset
Safari — prefs:root=Safari
Siri — prefs:root=General&path=Assistant
Sounds — prefs:root=Sounds
Software Update — prefs:root=General&path=SOFTWARE_UPDATE_LINK
Store — prefs:root=STORE
Twitter — prefs:root=TWITTER
Usage — prefs:root=General&path=USAGE
Wallpaper — prefs:root=Wallpaper
```
备注: 有的可能跳不过去 请把 path后面的 大写

* iOS8 以上貌似可以跳到对应的应用，然后去设置

```
NSString *prefs = [NSString stringWithFormat:@"prefs:root=%@",[[NSBundle mainBundle] bundleIdentifier]];
NSURL *url = [NSURL URLWithString:prefs];
if (kIOS8Later) {
	  url= [NSURL URLWithString:UIApplicationOpenSettingsURLString];
}
if([[UIApplication sharedApplication]canOpenURL:url]){
    [[UIApplication sharedApplication]openURL:url];
}
```

### 配置下 url type
