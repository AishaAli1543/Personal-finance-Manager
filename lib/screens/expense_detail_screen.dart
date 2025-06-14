import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: user == null
          ? const Center(child: Text('No user found'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .where('type', isEqualTo: 'expense')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No expense transactions found.'));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              return ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: Text(data['category'] ?? 'Expense'),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                trailing: Text(
                  '- Rs. ${data['amount']}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
