import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';

import 'income_detail_screen.dart';
import 'expense_detail_screen.dart';
import 'balance_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  String? userName;
  String? email;
  bool isLoading = true;

  double totalIncome = 0;
  double totalExpense = 0;
  double totalBalance = 0;

  Map<String, double> categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _calculateBudgetSummary();
    _calculateSpendingByCategory();
  }

  Future<void> _fetchUserName() async {
    final user = authService.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userName = doc.data()?['name'] ?? 'User';
        email = doc.data()?['email'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        userName = 'Guest';
        email = '';
        isLoading = false;
      });
    }
  }

  Future<void> _calculateBudgetSummary() async {
    final user = authService.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['type'] == 'income') {
        income += (data['amount'] ?? 0).toDouble();
      } else if (data['type'] == 'expense') {
        expense += (data['amount'] ?? 0).toDouble();
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      totalBalance = income - expense;
    });
  }

  Future<void> _calculateSpendingByCategory() async {
    final user = authService.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'expense')
        .get();

    final totals = <String, double>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Others';
      final amount = (data['amount'] ?? 0).toDouble();

      totals[category] = (totals[category] ?? 0) + amount;
    }

    setState(() {
      categoryTotals = totals;
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.purple;
      case 'Bills':
        return Colors.green;
      case 'Shopping':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.toggleDarkMode,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_income');
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _userProfileCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard('Income', 'Rs. ${totalIncome.toStringAsFixed(0)}', Colors.green),
                _summaryCard('Expense', 'Rs. ${totalExpense.toStringAsFixed(0)}', Colors.red),
                _summaryCard('Balance', 'Rs. ${totalBalance.toStringAsFixed(0)}', Colors.blue),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Spending Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: categoryTotals.isEmpty
                  ? const Center(child: Text('No expense data'))
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: categoryTotals.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value,
                      title: entry.key,
                      color: _getCategoryColor(entry.key),
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      radius: 60,
                      titlePositionPercentageOffset: 0.6,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3 / 2,
              children: [
                _quickAccessCard(Icons.add_circle, 'Add Income', '/add_income'),
                _quickAccessCard(Icons.money_off, 'Add Expense', '/add_expense'),
                _quickAccessCard(Icons.bar_chart, 'Reports', '/reports'),
                _quickAccessCard(Icons.savings, 'Goals', '/goals'),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: authService.currentUser?.uid)
                  .orderBy('date', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('No recent transactions');
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final isIncome = data['type'] == 'income';
                    final date = (data['date'] as Timestamp).toDate();
                    return ListTile(
                      leading: Icon(
                        isIncome ? Icons.work : Icons.shopping_cart,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      title: Text(data['category'] ?? ''),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      trailing: Text(
                        '${isIncome ? '+' : '-'} Rs. ${data['amount']}',
                        style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _userProfileCard() {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(userName ?? ''),
        subtitle: Text(email ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Optional: Add edit profile functionality
          },
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == 'Income') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeDetailScreen()));
          } else if (title == 'Expense') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseDetailScreen()));
          } else if (title == 'Balance') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceDetailScreen()));
          }
        },
        child: Card(
          color: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 16, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAccessCard(IconData icon, String title, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
