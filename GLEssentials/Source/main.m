/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Standard AppKit entry point.
 */

#import <Cocoa/Cocoa.h>

int main(int argc, char * argv[]) {

#ifdef TARGET_IOS
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
#else
    return NSApplicationMain(argc, (const char**)argv);
#endif
}
