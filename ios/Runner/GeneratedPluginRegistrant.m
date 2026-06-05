//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<encrypt_plugin/EncryptPlugin.h>)
#import <encrypt_plugin/EncryptPlugin.h>
#else
@import encrypt_plugin;
#endif

#if __has_include(<file_picker/FLTFilePickerPlugin.h>)
#import <file_picker/FLTFilePickerPlugin.h>
#else
@import file_picker;
#endif

#if __has_include(<flutter_local_notifications/FlutterLocalNotificationsPlugin.h>)
#import <flutter_local_notifications/FlutterLocalNotificationsPlugin.h>
#else
@import flutter_local_notifications;
#endif

#if __has_include(<flutter_secure_storage/FlutterSecureStoragePlugin.h>)
#import <flutter_secure_storage/FlutterSecureStoragePlugin.h>
#else
@import flutter_secure_storage;
#endif

#if __has_include(<local_auth_darwin/FLALocalAuthPlugin.h>)
#import <local_auth_darwin/FLALocalAuthPlugin.h>
#else
@import local_auth_darwin;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<share_plus/SharePlusPlatformPlugin.h>)
#import <share_plus/SharePlusPlatformPlugin.h>
#else
@import share_plus;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
  [FlutterSecureStoragePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSecureStoragePlugin"]];
  [FLALocalAuthPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLALocalAuthPlugin"]];
  [FlutterLocalNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]];
  [FLTFilePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFilePickerPlugin"]];
  [SharePlusPlatformPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharePlusPlatformPlugin"]];
}

@end
