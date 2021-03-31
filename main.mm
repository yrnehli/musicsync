#include <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#import "objc/runtime.h"

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

const char helpText[] = "Usage: `musicsync <json path>`\n";

int main(int argc, char **argv, char **envp) {
	if (argc == 1 || argc > 2) {
		printf(helpText);
		return 0;
	}

	CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(
		kCFAllocatorDefault,
		1, 
		&kCFTypeDictionaryKeyCallBacks,
		&kCFTypeDictionaryValueCallBacks
	);

	CFStringRef jsonFilepath = CFStringCreateWithCString(NULL, argv[1], kCFStringEncodingUTF8);
	CFDictionaryAddValue(userInfo, CFSTR("jsonFilepath"), jsonFilepath);

	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDistributedCenter(),
		CFSTR("xyz.henryli17.musicsync"),
		NULL,
		userInfo,
		kCFNotificationDeliverImmediately
	);

	return 0;
}