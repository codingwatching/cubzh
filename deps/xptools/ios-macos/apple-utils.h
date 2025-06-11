//
//  apple-utils.h
//  xptools
//
//  Created by Gaetan de Villele on 12/06/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

// this file can only be included in Objective-C source files
#ifdef __OBJC__

// --------------------------------------------------
// MARK: - Objective-C utilities -
// --------------------------------------------------

//
// NSData
//

@interface NSData (Base64UrlEncoding)
- (NSString *)base64UrlEncodedString;
@end

// --------------------------------------------------
// MARK: - C++ utilities -
// --------------------------------------------------

namespace vx {
namespace utils {

#if TARGET_OS_IPHONE
namespace ios {

// #import <UIKit/UIKit.h>

/// returns the root view controller (iOS)
UIViewController* getRootUIViewController();

} // namespace ios
#endif

} // namespace utils
} // namespace vx

#endif
