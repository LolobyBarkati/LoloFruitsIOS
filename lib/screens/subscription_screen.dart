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
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Decorative Gradients
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.05),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final controller = _controller!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 100.0, 24.0, 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "LOLO PREMIUM",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.isActive ? "Welcome to\nthe Inner Circle" : "Master Your\nFruit Logistics",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.isActive
                    ? "You have full access to our verified global network."
                    : "Connect directly with verified agents and cold storages worldwide.",
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5), height: 1.4),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildStatusSection(controller),
          const SizedBox(height: 40),
          
          const Text(
            "EXCLUSIVE FEATURES",
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 11),
          ),
          const SizedBox(height: 20),
          _buildFeaturesGrid(),
          
          const SizedBox(height: 40),
          
          if (!controller.isActive) ...[
             const Text(
              "SELECT A PLAN",
              style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 11),
            ),
            const SizedBox(height: 16),
            if (controller.monthlyProduct != null)
              _buildPlanCard(controller.monthlyProduct!, false),
            if (controller.monthlyProduct != null && controller.yearlyProduct != null)
              const SizedBox(height: 16),
            if (controller.yearlyProduct != null)
              _buildPlanCard(controller.yearlyProduct!, true),
            if (controller.monthlyProduct == null && controller.yearlyProduct == null)
              _buildErrorPlan(),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _controller?.restorePurchases(),
                child: const Text(
                  "Restore Purchases",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorPlan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white.withOpacity(0.2), size: 40),
          const SizedBox(height: 12),
          Text(
            'Store unavailable. Check your connection.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(SubscriptionController controller) {
    if (!controller.isActive && controller.expiryDate == null)
      return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: controller.isActive 
            ? [Colors.greenAccent.withOpacity(0.15), Colors.greenAccent.withOpacity(0.02)]
            : [Colors.redAccent.withOpacity(0.15), Colors.redAccent.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.isActive ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (controller.isActive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.isActive ? Icons.verified_rounded : Icons.history_rounded,
              color: controller.isActive ? Colors.greenAccent : Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isActive ? "Subscription Active" : "Access Expired",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (controller.expiryDate != null)
                  Text(
                    "${controller.isActive ? 'Next billing' : 'Expired on'}: ${DateFormat('MMMM dd, yyyy').format(controller.expiryDate!)}",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _featureItem(Icons.local_shipping_rounded, "Global Carriers", "Connect with verified transporters"),
          const Divider(height: 32, color: Colors.white10),
          _featureItem(Icons.verified_user_rounded, "Top-Tier Agents", "Verified agents with rating history"),
          const Divider(height: 32, color: Colors.white10),
          _featureItem(Icons.bolt_rounded, "Priority Tools", "Real-time rates and storage sheets"),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String sub) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(ProductDetails product, bool isRecommended) {
    final isYearly = product.id.contains('yearly');
    return GestureDetector(
      onTap: () => _controller?.buySubscription(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isRecommended ? Colors.amber : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isRecommended ? Colors.amberAccent : Colors.white.withOpacity(0.1),
            width: isRecommended ? 3 : 1,
          ),
          boxShadow: isRecommended
              ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecommended)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text("BEST VALUE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  Text(
                    isYearly ? "Annual Access" : "Monthly Access",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isRecommended ? Colors.black : Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isYearly ? "Save up to 30% annually" : "Flexibility to cancel anytime",
                    style: TextStyle(
                        fontSize: 12, color: isRecommended ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isRecommended ? Colors.black : Colors.white),
                ),
                Text(
                  isYearly ? "/year" : "/month",
                  style: TextStyle(
                      fontSize: 11, color: isRecommended ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}