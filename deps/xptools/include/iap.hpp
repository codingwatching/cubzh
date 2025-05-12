//
//  iap.hpp
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

#pragma once
#include <string>
#include <functional>

namespace vx {
namespace IAP {

struct PurchaseResult {
    enum class Status {
        Success,
        Failed,
        Cancelled,
        InvalidProduct,
        SuccessNotVerified, // seen as success from client, but server couldn't verify it
    };

    Status status;
    std::string productID;
    std::string transactionID; // For successful purchases
    std::string receiptData;   // Base64-encoded receipt for server validation
    std::string errorMessage;  // For failed or cancelled purchases

    PurchaseResult(Status s, const std::string& pid) : status(s), productID(pid) {}
};

bool isAvailable();
void purchase(std::string productID,
              std::string verifyURL,
              const std::unordered_map<std::string, std::string>& headers,
              std::function<void(const PurchaseResult&)> callback);

} // namespace IAP
} // namespace vx
