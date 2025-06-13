//
//  xp_http.hpp
//  xptools
//
//  Created by Gaetan de Villele on 12/06/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

// xptools
#include "URL.hpp"

namespace vx {
namespace http {

/// Clears the operating system's HTTP cache
void clearSystemHttpCache();

/// Clears the operating system's HTTP cache for a given URL
void clearSystemHttpCacheForURL(const vx::URL &url);

} // namespace http
} // namespace vx
