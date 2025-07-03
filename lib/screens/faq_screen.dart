import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  static const String routeName = '/faq';

  final List<Map<String, String>> faqList = [
    {
      'question': 'What is this app for?',
      'answer': 'This app helps fruit wholesalers and customers manage stock, orders, and subscriptions efficiently.'
    },
    {
      'question': 'How do I subscribe?',
      'answer': 'Go to the Subscription tab, select a plan, and complete the payment via Razorpay.'
    },
    {
      'question': 'Is screen recording secure?',
      'answer': 'Screen recording is used for monitoring. It may capture sensitive data, so use it responsibly as per our terms.'
    },
    {
      'question': 'Can I use the app without subscription?',
      'answer': 'No, a valid subscription is required to access product listings and place orders.'
    },
    {
      'question': 'How can I contact support?',
      'answer': 'Use the Contact Us option in the app settings to reach out via email or phone.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: Text(faqList[index]['question']!),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(faqList[index]['answer']!),
              )
            ],
          );
        },
      ),
    );
  }
}
