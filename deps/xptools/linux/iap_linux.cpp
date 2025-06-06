//
//  iap_linux.cpp
//  xptools
//
//  Created by Gaetan de Villele on 06/06/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

#include "iap.hpp"

bool vx::IAP::isAvailable() {
    // IAP is not available on Linux for now
    return false;
}

vx::IAP::Purchase_SharedPtr vx::IAP::purchase(std::string productID,
                                              std::string verifyURL,
                                              const std::unordered_map<std::string, std::string>& headers,
                                              std::function<void(const Purchase_SharedPtr&)> callback) {
    return nullptr;
}
