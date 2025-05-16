//
//  iap.hpp
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

#pragma once

// C++
#include <string>
#include <functional>
#include <memory>

namespace vx {
namespace IAP {

class Purchase;
typedef std::shared_ptr<Purchase> Purchase_SharedPtr;
typedef std::weak_ptr<Purchase> Purchase_WeakPtr;

class Purchase final {

public:
    enum class Status {
        Pending,
        Success,
        Failed,
        Cancelled,
        InvalidProduct,
        SuccessNotVerified, // seen as success from client, but server couldn't verify it
    };

    static Purchase_SharedPtr make(const std::string& productID,
                                   std::string verifyURL,
                                   const std::unordered_map<std::string, std::string>& verifyRequestHeaders);

    Status status;
    std::string verifyURL;
    std::unordered_map<std::string, std::string> verifyRequestHeaders;
    std::string productID;
    std::string transactionID; // For successful purchases
    std::string receiptData;   // Base64-encoded receipt for server validation
    std::string errorMessage;  // For failed or cancelled purchases
    std::function<void(const Purchase_SharedPtr&)> callback;

private:

    Purchase(const std::string& productID,
             std::string verifyURL,
             const std::unordered_map<std::string, std::string>& verifyRequestHeaders) :
    status(Status::Pending),
    verifyURL(verifyURL),
    verifyRequestHeaders(verifyRequestHeaders),
    productID(productID),
    transactionID(""), // will be assigned later on
    receiptData(""), // will be assigned later on
    errorMessage(""), // will be assigned later on
    callback(nullptr)
    {}

};

bool isAvailable();
Purchase_SharedPtr purchase(std::string productID,
                            std::string verifyURL,
                            const std::unordered_map<std::string, std::string>& headers,
                            std::function<void(const Purchase_SharedPtr&)> callback);

} // namespace IAP
} // namespace vx
