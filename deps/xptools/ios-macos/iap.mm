//
//  iap.mm
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2025 voxowl. All rights reserved.
//

#include "iap.hpp"
#include "URL.hpp"
#include "HttpRequest.hpp"
#include "cJSON.h"


#import <StoreKit/StoreKit.h>
#include <map>

// Private interface for StoreKit delegate
@interface IAPManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) NSMutableArray<SKProduct *> *productsCache;
@property (nonatomic, strong) NSValue *pending;
- (void)startPurchase:(vx::IAP::Purchase_SharedPtr) purchase;
@end

@implementation IAPManager
- (instancetype)init {
    self = [super init];
    if (self) {
        _productsRequest = nil;
        _productsCache = [[NSMutableArray alloc] init];
        _pending = nil;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)startPurchase:(vx::IAP::Purchase_SharedPtr) purchase {
    if (self.pending != nil) {
        NSLog(@"⚠️ purchase pending, can't start another one");
        return;
    }

    vx::IAP::Purchase_SharedPtr *purchasePtr = new vx::IAP::Purchase_SharedPtr(purchase);
    self.pending = [NSValue valueWithPointer: purchasePtr];

    NSString *nsProductID = [NSString stringWithUTF8String:purchase->productID.c_str()];

    // Check if product is already cached
    for (SKProduct *product in self.productsCache) {
        if ([product.productIdentifier isEqualToString:nsProductID]) {
            SKPayment *payment = [SKPayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            return;
        }
    }

    // Request product details
    NSSet *productIdentifiers = [NSSet setWithObject:nsProductID];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSString *productID = response.products.count > 0 ? response.products.firstObject.productIdentifier : response.invalidProductIdentifiers.firstObject;

    if (response.products.count > 0) {
        [self.productsCache addObjectsFromArray:response.products];
        // Start purchase for the first valid product
        SKProduct *product = response.products.firstObject;
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        NSLog(@"No products found for identifiers: %@", response.invalidProductIdentifiers);

        if (self.pending != nil) {
            vx::IAP::Purchase_SharedPtr *purchasePtr = static_cast<vx::IAP::Purchase_SharedPtr *>([self.pending pointerValue]);
            vx::IAP::Purchase_SharedPtr purchase = *purchasePtr;
            free(purchasePtr);
            self.pending = nil;

            purchase->errorMessage = "Invalid product identifier";
            if (purchase->callback != nullptr) {
                purchase->callback(purchase);
            }
        }
    }
    self.productsRequest = nil;
}

// SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (self.pending == nil) {
        return;
    }

    vx::IAP::Purchase_SharedPtr *purchasePtr = static_cast<vx::IAP::Purchase_SharedPtr *>([self.pending pointerValue]);
    vx::IAP::Purchase_SharedPtr purchase = *purchasePtr;

    for (SKPaymentTransaction *transaction in transactions) {
        NSString *productID = transaction.payment.productIdentifier;
        std::string transactionProductID = std::string([productID UTF8String]);

        if (transactionProductID != purchase->productID) {
            continue;
        }

        purchase->status = vx::IAP::Purchase::Status::Failed;

        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                // Retrieve receipt for server-side validation
                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
                if (receiptData) {
                    purchase->status = vx::IAP::Purchase::Status::Success;
                    purchase->transactionID = transaction.transactionIdentifier.UTF8String;
                    purchase->receiptData = [receiptData base64EncodedStringWithOptions:0].UTF8String;

                    vx::URL url = vx::URL::make(purchase->verifyURL);
                    vx::HttpRequest_SharedPtr req = vx::HttpRequest::make("POST", url.host(), url.port(), url.path(), url.queryParams(), true);
                    req->setHeaders(purchase->verifyRequestHeaders);

                    req->setCallback([transaction, purchase](vx::HttpRequest_SharedPtr req) mutable {
                        // process response
                        vx::HttpResponse& resp = req->getResponse();
                        // retrieve HTTP response status
                        const vx::HTTPStatus respStatus = resp.getStatus();
                        // retrieve HTTP response body
                        std::string respBody;
                        const bool didReadBody = resp.readAllBytes(respBody);

                        if ((respStatus != vx::HTTPStatus::OK && respStatus != vx::HTTPStatus::NOT_MODIFIED) || didReadBody == false) {
                            purchase->errorMessage = "couldn't verify purchase";
                            purchase->status = vx::IAP::Purchase::Status::SuccessNotVerified;
                        }

                        if (purchase->callback != nullptr) {
                            purchase->callback(purchase);
                        }
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    });

                    req->sendAsync();
                    free(purchasePtr);
                    self.pending = nil;
                    NSLog(@"Purchase completed for product: %@ (now verifying)", productID);

                } else {
                    purchase->errorMessage = "Failed to retrieve receipt";
                    NSLog(@"Failed to retrieve receipt for product: %@", productID);
                    if (purchase->callback != nullptr) {
                        purchase->callback(purchase);
                    }
                    free(purchasePtr);
                    self.pending = nil;
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                break;
            }
            case SKPaymentTransactionStateFailed: {
                if (transaction.error.code == SKErrorPaymentCancelled) {
                    purchase->status = vx::IAP::Purchase::Status::Cancelled;
                    purchase->errorMessage = "User cancelled the purchase";
                } else {
                    purchase->errorMessage = transaction.error.localizedDescription.UTF8String;
                }
                NSLog(@"Purchase failed for product %@: %s", productID, purchase->errorMessage.c_str());
                if (purchase->callback != nullptr) {
                    purchase->callback(purchase);
                }
                free(purchasePtr);
                self.pending = nil;
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored:
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

@end

// Static instance to manage IAP
static IAPManager *iapManager = nil;

bool vx::IAP::isAvailable() {
    return [SKPaymentQueue canMakePayments];
}

vx::IAP::Purchase_SharedPtr vx::IAP::purchase(std::string productID,
                                              std::string verifyURL,
                                              const std::unordered_map<std::string, std::string>& headers,
                                              std::function<void(const Purchase_SharedPtr&)> callback) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iapManager = [[IAPManager alloc] init];
    });
    Purchase_SharedPtr p = Purchase::make(productID, verifyURL, headers);
    p->callback = callback;
    [iapManager startPurchase: p];
    return p;
}
