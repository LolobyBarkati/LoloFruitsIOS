import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  static const String routeName = '/subscription';
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  SubscriptionController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = SubscriptionController(
      context: context,
      onLoadingChanged: (val) {
        if (mounted) setState(() => _isLoading = val);
      },
      onStateUpdate: () {
        if (mounted) setState(() {});
      },
    );
    _controller!.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Deep Navy/Black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final controller = _controller!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.isActive ? "Premium\nUser" : "Upgrade to\nPremium",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.isActive
                ? "You have access to all premium features."
                : "Get full access to all logistics tools and priority services.",
            style:
                TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          _buildStatusSection(controller),
          const SizedBox(height: 32),
          const Text(
            "BENEFITS",
            style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildFeaturesGrid(),
          const SizedBox(height: 40),
          if (!controller.isActive) ...[
            if (controller.monthlyProduct != null)
              _buildPlanCard(controller.monthlyProduct!, false),
            if (controller.monthlyProduct != null && controller.yearlyProduct != null)
              const SizedBox(height: 16),
            if (controller.yearlyProduct != null)
              _buildPlanCard(controller.yearlyProduct!, true),
            if (controller.monthlyProduct == null && controller.yearlyProduct == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Plans unavailable. Check your connection.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusSection(SubscriptionController controller) {
    if (!controller.isActive && controller.expiryDate == null)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            controller.isActive ? Icons.verified : Icons.error_outline,
            color: controller.isActive ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isActive
                    ? "Active Subscription"
                    : "Subscription Expired",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (controller.expiryDate != null)
                Text(
                  "Until ${DateFormat('MMM dd, yyyy').format(controller.expiryDate!)}",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Column(
      children: [
        _featureItem(Icons.local_shipping_outlined, "Transport Details",
            "View all carrier information"),
        _featureItem(Icons.verified_user_outlined, "Certified Agents",
            "Access only verified professionals"),
        _featureItem(Icons.support_agent_outlined, "Priority Support",
            "24/7 dedicated agent access"),
      ],
    );
  }

  Widget _featureItem(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ProductDetails product, bool isRecommended) {
    final isYearly = product.id == 'premium_access_yearly';
    return InkWell(
      onTap: () => _controller?.buySubscription(product),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecommended ? Colors.amber : Colors.white.withValues(alpha: 0.1),
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: isRecommended
              ? [
                  BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecommended)
                    const Text("MOST POPULAR",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber)),
                  Text(
                    product.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                Text(
                  isYearly ? "/year" : "/month",
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
