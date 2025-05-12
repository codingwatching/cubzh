//
//  iap.mm
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2020 voxowl. All rights reserved.
//

#include "iap.hpp"
#include "URL.hpp"
#include "HttpRequest.hpp"

#import <StoreKit/StoreKit.h>
#include <map>

// Private interface for StoreKit delegate
@interface IAPManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) NSMutableArray<SKProduct *> *products;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *callbacks; // Store C++ callbacks
- (void)startPurchase:(NSString *)productID withCallback:(std::function<void(const vx::IAP::PurchaseResult&)> *)callback;
@end

@implementation IAPManager
- (instancetype)init {
    self = [super init];
    if (self) {
        _products = [[NSMutableArray alloc] init];
        _callbacks = [[NSMutableDictionary alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)startPurchase:(NSString *)productID withCallback:(std::function<void(const vx::IAP::PurchaseResult&)> *)callback {
    // Store the callback
    if (callback) {
        self.callbacks[productID] = [NSValue valueWithPointer:new std::function<void(const vx::IAP::PurchaseResult&)>(*callback)];
    }

    // Check if product is already cached
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productID]) {
            SKPayment *payment = [SKPayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            return;
        }
    }

    // Request product details
    NSSet *productIdentifiers = [NSSet setWithObject:productID];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSString *productID = response.products.count > 0 ? response.products.firstObject.productIdentifier : response.invalidProductIdentifiers.firstObject;

    if (response.products.count > 0) {
        [self.products addObjectsFromArray:response.products];
        // Start purchase for the first valid product
        SKProduct *product = response.products.firstObject;
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        NSLog(@"No products found for identifiers: %@", response.invalidProductIdentifiers);
        // Notify app of invalid product ID
        vx::IAP::PurchaseResult result(vx::IAP::PurchaseResult::Status::InvalidProduct, productID.UTF8String);
        result.errorMessage = "Invalid product identifier";
        [self invokeCallbackForProductID:productID withResult:result];
    }
    self.productsRequest = nil;
}

// SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *productID = transaction.payment.productIdentifier;
        vx::IAP::PurchaseResult result(vx::IAP::PurchaseResult::Status::Failed, productID.UTF8String);

        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                // Retrieve receipt for server-side validation
                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
                if (receiptData) {
                    result.status = vx::IAP::PurchaseResult::Status::Success;
                    result.transactionID = transaction.transactionIdentifier.UTF8String;
                    result.receiptData = [receiptData base64EncodedStringWithOptions:0].UTF8String;

                    vx::URL url = vx::URL::make("https://api.cu.bzh/purchases/verify?userID=test");
                    vx::HttpRequest_SharedPtr req = vx::HttpRequest::make("POST", url.host(), url.port(), url.path(), url.queryParams(), true);
                    // req->setHeaders();

                    IAPManager *iapManager = self;

                    req->setCallback([iapManager, result, transaction](vx::HttpRequest_SharedPtr req) mutable {

                        // process response
                        vx::HttpResponse& resp = req->getResponse();

                        // retrieve HTTP response status
                        const vx::HTTPStatus respStatus = resp.getStatus();
                        // retrieve HTTP response body
                        std::string respBody;
                        const bool didReadBody = resp.readAllBytes(respBody);

                        if ((respStatus != vx::HTTPStatus::OK && respStatus != vx::HTTPStatus::NOT_MODIFIED) || didReadBody == false) {
                            result.errorMessage = "couldn't verify purchase";
                            result.status = vx::IAP::PurchaseResult::Status::SuccessNotVerified;
                        }

                        // parse response body
                        // vx::hub::World world;
                        // cJSON *jsonResp = cJSON_Parse(respBody.c_str());
                        // _decodeWorld(jsonResp, world);
                        // cJSON_Delete(jsonResp);
                        // jsonResp = nullptr;

                        // callback(true, respStatus, world.script, world.mapBase64, "", world.maxPlayers, std::unordered_map<std::string, std::string>());

                        NSString *nsProductID = [NSString stringWithUTF8String:result.productID.c_str()];
                        [iapManager invokeCallbackForProductID:nsProductID withResult:result];
                        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    });

                    req->sendAsync();

                    NSLog(@"Purchase completed for product: %@", productID);
                } else {
                    result.errorMessage = "Failed to retrieve receipt";
                    NSLog(@"Failed to retrieve receipt for product: %@", productID);
                    [self invokeCallbackForProductID:productID withResult:result];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                break;
            }
            case SKPaymentTransactionStateFailed: {
                if (transaction.error.code == SKErrorPaymentCancelled) {
                    result.status = vx::IAP::PurchaseResult::Status::Cancelled;
                    result.errorMessage = "User cancelled the purchase";
                } else {
                    result.errorMessage = transaction.error.localizedDescription.UTF8String;
                }
                NSLog(@"Purchase failed for product %@: %s", productID, result.errorMessage.c_str());
                [self invokeCallbackForProductID:productID withResult:result];
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

// Helper to invoke and clean up callback
- (void)invokeCallbackForProductID:(NSString *)productID withResult:(vx::IAP::PurchaseResult)result {
    NSValue *callbackValue = self.callbacks[productID];
    if (callbackValue) {
        auto *callback = static_cast<std::function<void(const vx::IAP::PurchaseResult&)> *>(callbackValue.pointerValue);
        if (callback) {
            (*callback)(result);
            delete callback;
        }
        [self.callbacks removeObjectForKey:productID];
    }
}

@end

// Static instance to manage IAP
static IAPManager *iapManager = nil;

bool vx::IAP::isAvailable() {
    return [SKPaymentQueue canMakePayments];
}

void vx::IAP::purchase(std::string productID,
                       std::string verifyURL,
                       const std::unordered_map<std::string, std::string>& headers,
                       std::function<void(const PurchaseResult&)> callback) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iapManager = [[IAPManager alloc] init];
    });
    NSString *nsProductID = [NSString stringWithUTF8String:productID.c_str()];
    [iapManager startPurchase:nsProductID withCallback:&callback];
}
