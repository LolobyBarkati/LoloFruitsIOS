import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionController {
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

  /// TWO product IDs
  final Set<String> _productIds = {
    "premium_access",
    "premium_access_yearly",
  };

  bool isActive = false;
  DateTime? expiryDate;

  List<ProductDetails> products = [];
  ProductDetails? monthlyProduct;
  ProductDetails? yearlyProduct;

  Future<void> init() async {
    onLoadingChanged(true);

    final available = await _iap.isAvailable();

    if (!available) {
      debugPrint("Play Billing not available");
      onLoadingChanged(false);
      return;
    }

    await _loadProducts();
    _listenPurchaseUpdates();
    await _restorePurchases();
    await checkPaymentStatus();

    onLoadingChanged(false);
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products not found: ${response.notFoundIDs}");
    }

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

  void _listenPurchaseUpdates() {
    _subscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          _handleSuccessfulPurchase(purchase);
        }

        if (purchase.status == PurchaseStatus.error) {
          debugPrint("Purchase Error: ${purchase.error}");
        }
      }
    });
  }

  Future<void> buySubscription(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    /// Detect plan type
    bool isYearly = purchase.productID == "premium_access_yearly";

    final expiry = now.add(
      Duration(days: isYearly ? 365 : 30),
    );

    await FirebaseFirestore.instance.collection("payments").add({
      "userId": user.uid,
      "email": user.email,
      "name": user.displayName ?? "",
      "paymentId": purchase.purchaseID,
      "orderId": purchase.purchaseID,
      "plan": isYearly ? "yearly" : "monthly",
      "amount": 0,
      "status": true,
      "subscription_date": now,
      "subscription_expiry": expiry,
      "timestamp": now,
    });

    isActive = true;
    expiryDate = expiry;

    onStateUpdate();

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subscription Activated 🎉")),
    );
  }

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

    final data = snap.docs.first.data();

    final expiry = (data['subscription_expiry'] as Timestamp).toDate();

    expiryDate = expiry;
    isActive = expiry.isAfter(DateTime.now());

    onStateUpdate();
  }

  void dispose() {
    _subscription?.cancel();
  }
}