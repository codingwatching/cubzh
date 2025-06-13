//
//  xp_http.mm
//  xptools
//
//  Created by Gaetan de Villele on 12/06/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

// apple
#import <Foundation/Foundation.h>

// xptools
#include "URL.hpp"

namespace vx {
namespace http {

void clearSystemHttpCache() {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

void clearSystemHttpCacheForURL(const vx::URL &url) {
    NSString *nsUrlString = [NSString stringWithUTF8String:url.toString().c_str()];
    NSURL *nsUrl = [NSURL URLWithString:nsUrlString];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:[NSURLRequest requestWithURL:nsUrl]];
}

} // namespace http
} // namespace vx
