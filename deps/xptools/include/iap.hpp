//
//  iap.hpp
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

#pragma once

#include <string>

namespace vx {
class IAP {
public:
    static bool IsAvailable();
    static void Purchase(std::string productID);
private:
    // void* _platformImpl;
};
}
