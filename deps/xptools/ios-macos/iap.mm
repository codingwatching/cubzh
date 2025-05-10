//
//  iap.mm
//  xptools
//
//  Created by Adrian Duermael on 05/10/2025.
//  Copyright © 2020 voxowl. All rights reserved.
//

#include "iap.hpp"

// Obj-C
#import <StoreKit/StoreKit.h>

// Private interface for StoreKit delegate
@interface IAPManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) NSMutableArray<SKProduct *> *products;
- (void)startPurchase:(NSString *)productID;
@end

@implementation IAPManager
- (instancetype)init {
    self = [super init];
    if (self) {
        _products = [[NSMutableArray alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)startPurchase:(NSString *)productID {
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
    if (response.products.count > 0) {
        [self.products addObjectsFromArray:response.products];
        // Start purchase for the first valid product
        SKProduct *product = response.products.firstObject;
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        NSLog(@"No products found for identifiers: %@", response.invalidProductIdentifiers);
        // TODO: Notify app of invalid product ID
    }
    self.productsRequest = nil;
}

// SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                // Retrieve receipt for server-side validation
                NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
                if (receiptData) {
                    // Send receipt to server (pseudo-code)
                    // [self sendReceiptToServer:receiptData forTransaction:transaction];
                    NSLog(@"Purchase completed for product: %@", transaction.payment.productIdentifier);
                    // TODO: Finish transaction only after server confirms
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                } else {
                    NSLog(@"Failed to retrieve receipt");
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                break;
            }
            case SKPaymentTransactionStateFailed:
                NSLog(@"Purchase failed: %@", transaction.error.localizedDescription);
                // TODO: Notify app of failure
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
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

bool vx::IAP::IsAvailable() {
    return [SKPaymentQueue canMakePayments];
}

void vx::IAP::Purchase(std::string productID) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iapManager = [[IAPManager alloc] init];
    });
    NSString *nsProductID = [NSString stringWithUTF8String:productID.c_str()];
    [iapManager startPurchase:nsProductID];
}
