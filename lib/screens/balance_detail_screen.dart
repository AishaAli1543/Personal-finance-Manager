import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class BalanceDetailScreen extends StatelessWidget {
  const BalanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Balance Details')),
      body: user == null
          ? const Center(child: Text('No user found'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final isIncome = data['type'] == 'income';
              final date = (data['date'] as Timestamp).toDate();

              return ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(data['category'] ?? ''),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                trailing: Text(
                  '${isIncome ? '+' : '-'} Rs. ${data['amount']}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
