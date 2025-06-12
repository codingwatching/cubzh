//
//  Macros.h
//  xptools
//
//  Created by Gaetan de Villele on 04/02/2020.
//  Copyright © 2020 voxowl. All rights reserved.
//

#pragma once

/// disable assign operator (=) and copy constructor for the given type
#define VX_DISALLOW_COPY_AND_ASSIGN(TypeName) \
TypeName( const TypeName& ) = delete;\
TypeName& operator=( const TypeName& ) = delete;

// Don't use our own HTTP caching on the following platforms:
// - iOS & macOS (Apple's HTTP API is taking care of it)
// - wasm (the web browser is taking care of it)
#if !defined(__VX_PLATFORM_WASM) && !defined(__VX_PLATFORM_IOS) && !defined(__VX_PLATFORM_MACOS)
#define __VX_USE_HTTP_CACHING 1
#else
#define __VX_USE_HTTP_CACHING 0
#endif
