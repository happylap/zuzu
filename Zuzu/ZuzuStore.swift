//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import StoreKit

private let Log = Logger.defaultLogger

@objc public protocol ZuzuStorePurchaseHandler : NSObjectProtocol {
    
    func onPurchased(store: ZuzuStore, transaction: SKPaymentTransaction)

    func onFailed(store: ZuzuStore, transaction: SKPaymentTransaction)
}

/// Notification that is generated when a product is purchased.
public let ProductPurchasedNotification = "ProductPurchasedNotification"

/// Product identifiers are unique strings registered on the app store.
public typealias ProductIdentifier = String

/// Completion handler called when products are fetched.
public typealias RequestProductsCompletionHandler = (success: Bool, products: [SKProduct]) -> ()

/// Transaction handler called when there is any transaction status update.
public typealias PurchaseHandler = (store: ZuzuStore, transaction: SKPaymentTransaction) -> Bool

public struct ZuzuProduct {
    var productIdentifier: String
    var localizedTitle: String
    var price: NSDecimalNumber
    var priceLocale: NSLocale
}

/// A Helper class for In-App-Purchases, it can fetch products, tell you if a product has been purchased,
/// purchase products, and restore purchases.  Uses NSUserDefaults to cache if a product has been purchased.
public class ZuzuStore: NSObject  {
    
    // MARK: - Private Members
    
    // Used to keep track of the possible products and which ones have been purchased.
    private let productIdentifiers: Set<ProductIdentifier>
    
    private var validSKProducts: [SKProduct]?
    
    // Used by SKProductsRequestDelegate
    private var productsRequest: SKProductsRequest?
    private var productsRequestHandler: RequestProductsCompletionHandler?
    private var purchaseHandler: ZuzuStorePurchaseHandler?
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: ZuzuStore {
        struct Singleton {
            static let instance = ZuzuStore(productIdentifiers: ZuzuProducts.productIdentifiers)
        }
        
        return Singleton.instance
    }
    
    // MARK: - Private API
    
    /// Validate the receipt with remote Apple server
    private func validateReceipt(appStoreReceiptURL : NSURL?, onCompletion: (Bool) -> Void) {
        
        validateReceiptInternal(appStoreReceiptURL, isProd: true) { (statusCode: Int?) -> Void in
            guard let status = statusCode else {
                onCompletion(false)
                return
            }
            
            // This receipt is from the test environment, but it was sent to the production environment for verification.
            if status == 21007 {
                self.validateReceiptInternal(appStoreReceiptURL, isProd: false) { (statusCode: Int?) -> Void in
                    guard let statusValue = statusCode else {
                        onCompletion(false)
                        return
                    }
                    
                    // 0 if the receipt is valid
                    if statusValue == 0 {
                        onCompletion(true)
                    } else {
                        onCompletion(false)
                    }
                    
                }
                
                // 0 if the receipt is valid
            } else if status == 0 {
                onCompletion(true)
            } else {
                onCompletion(false)
            }
        }
    }
    
    private func receiptData(appStoreReceiptURL : NSURL?) -> NSData? {
        
        guard let receiptURL = appStoreReceiptURL,
            receipt = NSData(contentsOfURL: receiptURL) else {
                return nil
        }
        
        do {
            let receiptData = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            let requestContents = ["receipt-data" : receiptData]
            let requestData = try NSJSONSerialization.dataWithJSONObject(requestContents, options: [])
            return requestData
        }
        catch let error as NSError {
            print(error)
        }
        
        return nil
    }
    
    private func validateReceiptInternal(appStoreReceiptURL : NSURL?, isProd: Bool , onCompletion: (Int?) -> Void) {
        
        let serverURL = isProd ? "https://buy.itunes.apple.com/verifyReceipt" : "https://sandbox.itunes.apple.com/verifyReceipt"
        
        guard let receiptData = receiptData(appStoreReceiptURL),
            url = NSURL(string: serverURL)  else {
                onCompletion(nil)
                return
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = receiptData
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            guard let data = data where error == nil else {
                onCompletion(nil)
                return
            }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options:[])
                print(json)
                guard let statusCode = json["status"] as? Int else {
                    onCompletion(nil)
                    return
                }
                onCompletion(statusCode)
            }
            catch let error as NSError {
                print(error)
                onCompletion(nil)
            }
        })
        task.resume()
    }
    
    // MARK: - Public API
    
    /// Initializer.  Pass in the set of ProductIdentifiers supported by the app.
    internal init(productIdentifiers: Set<ProductIdentifier>) {
        
        self.productIdentifiers = productIdentifiers
        
        super.init()
    }
    
    ///Start ZuzuStore. The transaction observer will be registered
    internal func start() {
        
        Log.enter()
        
        /// Observe the transaction
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    ///Stop ZuzuStore. The transaction observer will be deregistered
    internal func stop() {
        
        Log.enter()
        
        /// Stop observing the transaction
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    /// Request the list of SKProducts from the AppStore. The handler will get called with the list of products.
    internal func requestProducts(handler: RequestProductsCompletionHandler) {
        
        Log.debug("Fetch product list...")
        
        productsRequestHandler = handler
        
        /// Init SKProductsRequest
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        
        /// Receive response for product requests
        productsRequest?.delegate = self
        
        productsRequest?.start()
    }
    
    /// Read local In-App Purchase receipt
    internal func readReceipt() -> NSData? {
        
        return StoreReceiptObtainer.sharedInstance.readReceipt()
        
    }
    
    /// Refresh the app store receipt and pass the binary result to the handler
    internal func fetchReceipt(handler: RequestReceiptCompletionHandler) {
        
        StoreReceiptObtainer.sharedInstance.fetchReceipt(handler)
        
    }
    
    /// Make purchase of a product.
    /// return false: if there exists an unfinished transaction for the product to purchase
    /// return true: if the payment is sent to the server successfully
    internal func makePurchase(product: ZuzuProduct, handler: ZuzuStorePurchaseHandler?) -> Bool {
        
        purchaseHandler = handler
        
        let productIdentifier = product.productIdentifier
        
        Log.debug("Buying \(productIdentifier)...")
        
        let unfinishedTrans = self.getUnfinishedTransactions()
        
        let transForProduct = unfinishedTrans.filter { (trans) -> Bool in
            return (trans.payment.productIdentifier == productIdentifier)
        }
        
        if(transForProduct.isEmpty) {
            
            Log.debug("Add payment for product = \(productIdentifier)...")
            
            if let products = self.validSKProducts,
                let targetProduct = products.filter({ (skProduct) -> Bool in
                return (skProduct.productIdentifier == productIdentifier) }).first {
                
                let payment = SKPayment(product: targetProduct)
                
                SKPaymentQueue.defaultQueue().addPayment(payment)
                
                return true
                
            } else {
                
                Log.debug("The product = \(productIdentifier) is not a valid SKProduct...")
                return false
            }
            
        } else {
            
            Log.debug("You still have unfinished transaction for product = \(productIdentifier)...")
            
            return false
            
        }
    }
    
    /// Finish the transaction so that Apple server would know the transaction is complete
    internal func finishTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    /// If the state of whether purchases have been made is lost
    /// (e.g. the user deletes and reinstalls the app) this will recover the purchases.
    /// * Only non-consumable products/ renewable subscription/ free subscription can be restored by AppStore
    internal func restorePreviousPurchase() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    /// Get list of unfinished transactions.
    /// We should deliver the service for these transactions before we actually finish them
    internal func getUnfinishedTransactions() -> [SKPaymentTransaction] {
        
        return SKPaymentQueue.defaultQueue().transactions.filter({ (trans) -> Bool in
            
            Log.warning("transaction = \(trans.transactionIdentifier), transaction = \(trans.transactionState), product = \(trans.payment.productIdentifier)")
            
            return trans.transactionState == .Purchased
        })
        
    }
    
    /// Check if the current device is allowed to make the payment
    internal class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
}


// MARK: - SKProductsRequestDelegate
// SKProductsRequestDelegate: to get a list of products, their titles, descriptions, and prices from the Apple server
extension ZuzuStore: SKProductsRequestDelegate {
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        Log.debug("Loaded list of products...")
        
        // Cache product list
        self.validSKProducts = response.products
        
        let products = self.validSKProducts ?? [SKProduct]()
        
        productsRequestHandler?(success: true, products: products)
        
        clearRequest()
        
        // Debug printing
        for p in products {
            Log.debug("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        Log.debug("Failed to load list of products.")
        Log.debug("Error: \(error)")
        
        productsRequestHandler?(success: false, products: [SKProduct]())
        
        clearRequest()
    }
    
    private func clearRequest() {
        productsRequestHandler = nil
    }
}

// MARK: - SKProductsRequestDelegate
// SKPaymentTransactionObserver: receive the result for the transactions
extension ZuzuStore: SKPaymentTransactionObserver {
    
    /// For each transaction act accordingly
    /// Save in the purchased cache, Issue notifications, Mark the transaction as complete.
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        Log.enter()
        
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
                ///For now, we do not handle transactions with the following states
            case .Restored:
                break
            case .Deferred:
                break
            case .Purchasing:
                break
            }
        }
    }
    
    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError){
        
        Log.warning(error.description)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        
        Log.warning(queue.description)
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {
        Log.warning("completeTransaction... \(transaction.transactionIdentifier), product = \(transaction.payment.productIdentifier)")

        purchaseHandler?.onPurchased(self, transaction: transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        Log.warning("restoreTransaction... \(transaction.transactionIdentifier), product = \(transaction.payment.productIdentifier)")
        
        //let productIdentifier = transaction.originalTransaction!.payment.productIdentifier

        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        Log.warning("failedTransaction...\(transaction.transactionIdentifier), product = \(transaction.payment.productIdentifier)")
        if transaction.error!.code != SKErrorPaymentCancelled {
        //if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            Log.warning("Transaction error: \(transaction.error!.localizedDescription)")
        }
        
        purchaseHandler?.onFailed(self, transaction: transaction)
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
}