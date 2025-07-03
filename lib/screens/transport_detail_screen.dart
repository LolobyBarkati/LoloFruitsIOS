import 'package:flutter/material.dart';

class TransportDetailScreen extends StatelessWidget {
  static const String routeName = '/transportdetails';
  final Map<String, dynamic> entry;

  const TransportDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transport Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Company: ${entry['company']}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Number: ${entry['number']}"),
            Text("From: ${entry['from']}"),
            Text("To: ${entry['to']}"),
          ],
        ),
      ),
    );
  }
}
