import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionController with WidgetsBindingObserver {

  final BuildContext context;
  final Function(bool) onLoadingChanged;
  final VoidCallback onStateUpdate;

  SubscriptionController({
    required this.context,
    required this.onLoadingChanged,
    required this.onStateUpdate,
  });

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Set<String> _productIds = {
    "premium_access",
    "premium_access_yearly",
  };

  bool isActive = false;
  DateTime? expiryDate;

  List<ProductDetails> products = [];
  ProductDetails? monthlyProduct;
  ProductDetails? yearlyProduct;

  /// INIT
  Future<void> init() async {

    onLoadingChanged(true);

    WidgetsBinding.instance.addObserver(this);

    final available = await _iap.isAvailable();

    if (!available) {
      onLoadingChanged(false);
      return;
    }

    await _loadProducts();

    _listenPurchaseUpdates();

    await checkPaymentStatus();

    onLoadingChanged(false);
  }

  /// LOAD PRODUCTS
  Future<void> _loadProducts() async {

    final response = await _iap.queryProductDetails(_productIds);

    products = response.productDetails;

    for (var product in products) {

      if (product.id == "premium_access") {
        monthlyProduct = product;
      }

      if (product.id == "premium_access_yearly") {
        yearlyProduct = product;
      }

    }

    onStateUpdate();
  }

  /// PURCHASE LISTENER
  void _listenPurchaseUpdates() {

    _subscription = _iap.purchaseStream.listen((purchases) async {

      for (final purchase in purchases) {

        /// ONLY process real purchase
        if (purchase.status == PurchaseStatus.purchased) {

          await _handlePurchase(purchase);

        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      }

    });
  }

  /// BUY SUBSCRIPTION
  Future<void> buySubscription(ProductDetails product) async {

    final purchaseParam = PurchaseParam(productDetails: product);

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);

  }

  /// RESTORE PURCHASES
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// HANDLE PURCHASE
  Future<void> _handlePurchase(PurchaseDetails purchase) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    /// Prevent duplicate purchase records
    final existing = await FirebaseFirestore.instance
        .collection('payments')
        .where('paymentId', isEqualTo: purchase.purchaseID)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    final isYearly = purchase.productID == "premium_access_yearly";

    final expiry = now.add(
      Duration(days: isYearly ? 365 : 30),
    );

    await FirebaseFirestore.instance.collection('payments').add({

      "userId": user.uid,
      "email": user.email,
      "paymentId": purchase.purchaseID,
      "productId": purchase.productID,
      "purchaseToken": purchase.verificationData.serverVerificationData,

      // iOS: links this record to future Apple ASSN renewal webhooks
      // On first purchase, transactionId == originalTransactionId on Apple's side
      if (Platform.isIOS) "originalTransactionId": purchase.purchaseID,

      "plan": isYearly ? "yearly" : "monthly",
      "status": true,
      "subscription_date": now,
      "subscription_expiry": expiry,
      "timestamp": FieldValue.serverTimestamp(),
      "source": "app"

    });

    expiryDate = expiry;
    isActive = true;

    onStateUpdate();
  }

  /// CHECK STATUS
  Future<void> checkPaymentStatus() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {

      isActive = false;
      onStateUpdate();
      return;

    }

    final expiry =
        (snap.docs.first.data()['subscription_expiry'] as Timestamp).toDate();

    expiryDate = expiry;

    isActive = expiry.isAfter(DateTime.now());

    onStateUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {

      checkPaymentStatus();

    }

  }

  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    _subscription?.cancel();

  }

}