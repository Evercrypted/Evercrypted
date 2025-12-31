import 'dart:async';
import 'dart:async';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Service for handling Apple In-App Purchase subscriptions
class AppleIAPService {
  static final AppleIAPService _instance = AppleIAPService._internal();
  factory AppleIAPService() => _instance;
  AppleIAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // TODO: Replace with actual product ID from App Store Connect
  static const String monthlySubscriptionId = 'Monthly_9.9';
  static const Set<String> _productIds = {monthlySubscriptionId};

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _available = false;

  // Restore purchase tracking
  Completer<bool>? _restoreCompleter;
  bool _isRestoring = false;
  bool get isAvailable => _available;

  /// Initialize the IAP service
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('AppleIAPService: Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) =>
          debugPrint('AppleIAPService: Purchase stream error: $error'),
    );

    // Load products
    await loadProducts();

    // Complete any pending transactions on iOS
    if (Platform.isIOS) {
      final paymentWrapper = SKPaymentQueueWrapper();
      final transactions = await paymentWrapper.transactions();
      for (final transaction in transactions) {
        await paymentWrapper.finishTransaction(transaction);
      }
    }
  }

  /// Load available subscription products
  Future<void> loadProducts() async {
    if (!_available) return;

    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          'AppleIAPService: Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    debugPrint('AppleIAPService: Loaded ${_products.length} products');
  }

  /// Purchase the monthly subscription
  Future<bool> purchaseSubscription() async {
    if (!_available || _products.isEmpty) {
      debugPrint(
          'AppleIAPService: Cannot purchase - store not available or no products');
      return false;
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == monthlySubscriptionId,
      );

      // Create platform specific purchase param
      PurchaseParam purchaseParam;
      if (Platform.isIOS) {
        // Ensure we supply AppStoreProductDetails for iOS
        // cast to AppStoreProductDetails if possible
        if (product is AppStoreProductDetails) {
          purchaseParam = AppStorePurchaseParam(productDetails: product);
        } else {
          debugPrint(
              'AppleIAPService: Product is not AppStoreProductDetails on iOS');
          purchaseParam = PurchaseParam(productDetails: product);
        }
      } else {
        purchaseParam = PurchaseParam(productDetails: product);
      }

      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('AppleIAPService: Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  /// Returns true if any purchases were found and restored, false otherwise
  Future<bool> restorePurchases() async {
    if (!_available) return false;

    _isRestoring = true;
    _restoreCompleter = Completer<bool>();

    try {
      await _iap.restorePurchases();

      // Wait up to 5 seconds for restoration to complete
      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('AppleIAPService: Restore timed out, no purchases found');
          return false;
        },
      );

      return result;
    } finally {
      _isRestoring = false;
      _restoreCompleter = null;
    }
  }

  /// Handle purchase updates from the stream
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    bool foundRestored = false;

    for (final purchase in purchases) {
      debugPrint(
          'AppleIAPService: Purchase update - ${purchase.productID}: ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Show pending UI if needed
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.status == PurchaseStatus.restored) {
            foundRestored = true;
          }
          // Verify with server and activate subscription
          await _verifyAndActivatePurchase(purchase);
          break;

        case PurchaseStatus.error:
          debugPrint('AppleIAPService: Purchase error: ${purchase.error}');
          break;

        case PurchaseStatus.canceled:
          debugPrint('AppleIAPService: Purchase canceled');
          break;
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    // If we're in restore mode and processed purchases, complete the restore
    if (_isRestoring &&
        _restoreCompleter != null &&
        !_restoreCompleter!.isCompleted) {
      // Small delay to ensure all purchases are processed
      await Future.delayed(const Duration(milliseconds: 500));
      // Check again after delay in case timeout completed it
      if (!_restoreCompleter!.isCompleted) {
        _restoreCompleter!.complete(foundRestored);
      }
    }
  }

  /// Verify purchase with server and activate subscription
  Future<void> _verifyAndActivatePurchase(PurchaseDetails purchase) async {
    try {
      // Get the original transaction ID for iOS
      String? originalTransactionId;
      if (Platform.isIOS && purchase is AppStorePurchaseDetails) {
        originalTransactionId = purchase.skPaymentTransaction
                .originalTransaction?.transactionIdentifier ??
            purchase.skPaymentTransaction.transactionIdentifier;
      }

      // Send verification request to server
      final response = await AppHttpClient.message(
        channel: SocketChannelTypes.payment,
        type: 'verifyApplePurchase',
        payload: {
          'productId': purchase.productID,
          'transactionId': purchase.purchaseID,
          'originalTransactionId': originalTransactionId,
          'verificationData': purchase.verificationData.serverVerificationData,
        },
      );

      if (response['success'] == true && response['subscription'] != null) {
        // Update local profile with subscription
        final profileService = ProfileService();
        final profile = profileService.getProfile();
        if (profile != null) {
          final updatedProfile = profile.copyWith(
            subscription:
                ProfileSubscription.fromJson(response['subscription']),
          );
          Auth.setAuth(profile: updatedProfile);
        }
        debugPrint('AppleIAPService: Subscription activated successfully');
      } else {
        debugPrint(
            'AppleIAPService: Server verification failed: ${response['error']}');
      }
    } catch (e) {
      debugPrint('AppleIAPService: Verification error: $e');
    }
  }

  /// Get subscription product details
  ProductDetails? getSubscriptionProduct() {
    print(_products);
    if (_products.isEmpty) return null;
    try {
      return _products.firstWhere(
        (p) => p.id == monthlySubscriptionId,
      );
    } catch (_) {
      return _products.first;
    }
  }

  /// Dispose of the service
  void dispose() {
    _subscription?.cancel();
  }
}
