//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import StoreKit

private let Log = Logger.defaultLogger

/// Notification that is generated when a product is purchased.
public let ProductPurchasedNotification = "ProductPurchasedNotification"

/// Product identifiers are unique strings registered on the app store.
public typealias ProductIdentifier = String

/// Completion handler called when products are fetched.
public typealias RequestProductsCompletionHandler = (success: Bool, products: [SKProduct]) -> ()

/// Transaction handler called when there is any transaction status update.
public typealias TransactionHandler = (store: ZuzuStore, transaction: SKPaymentTransaction) -> Bool

/// A Helper class for In-App-Purchases, it can fetch products, tell you if a product has been purchased,
/// purchase products, and restore purchases.  Uses NSUserDefaults to cache if a product has been purchased.
public class ZuzuStore: NSObject  {
    
    /// MARK: - Private Properties
    
    // Used to keep track of the possible products and which ones have been purchased.
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers = Set<ProductIdentifier>()
    
    // Used by SKProductsRequestDelegate
    private var productsRequest: SKProductsRequest?
    private var completionHandler: RequestProductsCompletionHandler?
    private var transactionHandler: TransactionHandler?
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: ZuzuStore {
        struct Singleton {
            static let instance = ZuzuStore(productIdentifiers: ZuzuProducts.productIdentifiers)
        }
        
        return Singleton.instance
    }
    
    /// MARK: - Private API
    
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
    
    /// MARK: - Public API
    
    /// Initialize the helper.  Pass in the set of ProductIdentifiers supported by the app.
    public init(productIdentifiers: Set<ProductIdentifier>) {
        
        self.productIdentifiers = productIdentifiers
        
        super.init()
    }
    
    ///Start
    public func start() {
        
        /// Observe the transaction
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    public func stop() {
        
        /// Observe the transaction
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    /// Gets the list of SKProducts from the Apple server calls the handler with the list of products.
    public func requestProducts(handler: RequestProductsCompletionHandler) {
        
        completionHandler = handler
        
        /// Init SKProductsRequest
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        
        for productIdentifier in productIdentifiers {
            let purchased = NSUserDefaults.standardUserDefaults().boolForKey(productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                Log.debug("Previously purchased: \(productIdentifier)")
            }
            else {
                Log.debug("Not purchased: \(productIdentifier)")
            }
        }
        
        /// Receive response for product requests
        productsRequest?.delegate = self
        
        productsRequest?.start()
    }
    
    public func readReceipt() -> NSData? {
        
        return StoreReceiptObtainer.sharedInstance.readReceipt()
        
    }
    
    /// Obtain the app store receipt
    public func fetchReceipt(handler: RequestReceiptCompletionHandler) {
        
        StoreReceiptObtainer.sharedInstance.fetchReceipt(handler)
        
    }
    
    /// Make purchase of a product.
    public func makePurchase(product: SKProduct) {
        Log.debug("Buying \(product.productIdentifier)...")
        
        
        let queue = SKPaymentQueue.defaultQueue()
        
        for trans in queue.transactions {
            Log.debug("Unfinished: \(trans.payment.productIdentifier), \(trans.transactionState)...")
        }
        
        validateReceipt(NSBundle.mainBundle().appStoreReceiptURL) { (success: Bool) -> Void in
            print("validateReceipt: \(success)")
            
            let payment = SKPayment(product: product)
            
            SKPaymentQueue.defaultQueue().addPayment(payment)
        }
    }
    
    
    /// Get list of unfinished transactions so that we can try to deliver/persist the service before we actually finish the transactions
    public func getUnfinishedTransactionsForState(state: SKPaymentTransactionState) -> [SKPaymentTransaction] {
        
        return SKPaymentQueue.defaultQueue().transactions.filter({ (trans) -> Bool in
            return trans.transactionState == .Purchased
        })
        
    }
    
    public func finishTransaction(transaction: SKPaymentTransaction) {
        
        
        /// Finish the transaction
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    /// If the state of whether purchases have been made is lost  (e.g. the
    /// user deletes and reinstalls the app) this will recover the purchases.
    /// Only non-consumable products/ renewable subscription/ free subscription can be restored by AppStore
    public func restorePreviousPurchase() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    /// Check if the current device is allowed to make the payment
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// Given the product identifier, returns true if that product has been purchased.
    /// Check against the locally cached data
    public func isProductPurchased(productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public func validateReceipt(appStoreReceiptURL : NSURL?, onCompletion: (Bool) -> Void) {
        
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
}


/// MARK: - SKProductsRequestDelegate
// SKProductsRequestDelegate: to get a list of products, their titles, descriptions, and prices from the Apple server
extension ZuzuStore: SKProductsRequestDelegate {
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        Log.debug("Loaded list of products...")
        let products = response.products
        completionHandler?(success: true, products: products)
        clearRequest()
        
        // debug printing
        for p in products {
            Log.debug("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        Log.debug("Failed to load list of products.")
        Log.debug("Error: \(error)")
        clearRequest()
    }
    
    private func clearRequest() {
        completionHandler = nil
    }
}

/// MARK: - SKProductsRequestDelegate
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
            case .Restored:
                restoreTransaction(transaction)
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
        Log.warning("completeTransaction... \(transaction.transactionIdentifier)")
        provideContentForProductIdentifier(transaction.payment.productIdentifier)
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        let productIdentifier = transaction.originalTransaction!.payment.productIdentifier
        Log.warning("restoreTransaction... \(productIdentifier)")
        provideContentForProductIdentifier(productIdentifier)
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        Log.warning("failedTransaction...\(transaction.transactionIdentifier)")
        if transaction.error!.code != SKErrorPaymentCancelled {
            Log.debug("Transaction error: \(transaction.error!.localizedDescription)")
        }
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    // Helper: Saves the fact that the product has been purchased and posts a notification.
    private func provideContentForProductIdentifier(productIdentifier: String) {
        purchasedProductIdentifiers.insert(productIdentifier)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(ProductPurchasedNotification, object: productIdentifier)
    }
}