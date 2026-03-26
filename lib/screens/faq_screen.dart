import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  static const String routeName = '/faq';

  // Your FAQ Data
  final List<Map<String, String>> faqList = [
    {
      'question': 'What is Lolo Fruits app?',
      'answer': 'Lolo Fruits is a platform that connects fruit wholesalers, agents, transport providers, and buyers. It provides access to product listings, pricing details, and contact information in one place.'
    },
    {
      'question': 'Do I need a subscription to use the app?',
      'answer': 'Yes. A valid subscription is required to access premium features such as pricing details, contact numbers, transport and agent information.'
    },
    {
      'question': 'What subscription plans are available?',
      'answer': 'We offer monthly and yearly subscription plans. Pricing may vary and will be displayed clearly before purchase inside the app.'
    },
    {
      'question': 'How do I subscribe?',
      'answer': 'Tap on "Upgrade to Premium" and complete the payment securely through Google Play billing.'
    },
    {
      'question': 'Will my subscription renew automatically?',
      'answer': 'Yes. Subscriptions renew automatically at the end of each billing cycle unless cancelled from your Google Play account.'
    },
    {
      'question': 'How can I cancel my subscription?',
      'answer': 'You can cancel your subscription anytime from your Google Play account under Payments & Subscriptions. After cancellation, you will retain access until the current period ends.'
    },
    {
      'question': 'Do you provide refunds?',
      'answer': 'All sales are final. Since our service provides instant access to premium business data, we do not provide refunds once a subscription is activated, as per Google Play’s digital goods policy.'
    },
    {
      'question': 'Is my data secure?',
      'answer': 'Yes. We take appropriate measures to protect your data. However, users are advised not to share sensitive information unnecessarily.'
    },
    {
      'question': 'What information can I access after subscribing?',
      'answer': 'Subscribers can access detailed product pricing, cold storage details, agent contacts, transport information, and direct seller communication.'
    },
    {
      'question': 'Can I contact sellers directly?',
      'answer': 'Yes. After subscribing, you can view and contact sellers, agents, and transport providers directly using the details provided in the app.'
    },
    {
      'question': 'What should I do if the app is not working properly?',
      'answer': 'Please restart the app or check your internet connection. If the issue continues, contact support through the app.'
    },
    {
      'question': 'How can I contact support?',
      'answer': 'You can contact us via the Contact Us section in the Profile for any issues, feedback, or assistance.'
    },
  ];

  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color darkBlue = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('FAQs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Visual Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Help Center",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Find answers to your questions about the Lolo Fruits platform.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAQ List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildFaqItem(faqList[index]);
                },
                childCount: faqList.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // Removes the highlight gray color and divider on expansion
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryGreen,
          collapsedIconColor: Colors.grey.shade400,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline_rounded, color: primaryGreen, size: 20),
          ),
          title: Text(
            faq['question']!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: darkBlue.withOpacity(0.9),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 24, 20),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}