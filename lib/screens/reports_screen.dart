// reports_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final authService = AuthService();
  DateTime selectedDate = DateTime.now();

  double totalIncome = 0;
  double totalExpense = 0;
  double totalBalance = 0;

  List<QueryDocumentSnapshot> monthlyTransactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthlyReport();
  }

  Future<void> _fetchMonthlyReport() async {
    setState(() {
      isLoading = true;
    });

    final user = authService.currentUser;
    if (user == null) return;

    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
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
      monthlyTransactions = snapshot.docs;
      isLoading = false;
    });
  }

  Future<void> _pickMonthYear() async {
    final picked = await showMonthYearPicker(context);
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _fetchMonthlyReport();
    }
  }

  Future<DateTime?> showMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    DateTime selected = selectedDate;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = selected.year;
        int selectedMonth = selected.month;

        return AlertDialog(
          title: const Text('Select Month & Year'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(10, (index) => now.year - 5 + index)
                      .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedYear = val;
                      });
                    }
                  },
                ),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) => index + 1)
                      .map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat.MMMM().format(DateTime(0, month)))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedMonth = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(DateTime(selectedYear, selectedMonth));
                },
                child: const Text('OK')),
          ],
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarChartData() {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: totalIncome,
            color: Colors.green,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          )
        ],
        showingTooltipIndicators: [0],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: totalExpense,
            color: Colors.red,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          )
        ],
        showingTooltipIndicators: [0],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final monthYearStr = DateFormat.yMMM().format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickMonthYear,
            tooltip: 'Select Month & Year',
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchMonthlyReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report for: $monthYearStr',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryCard('Income', totalIncome, Colors.green),
                  _summaryCard('Expense', totalExpense, Colors.red),
                  _summaryCard('Balance', totalBalance, Colors.blue),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Income vs Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    maxY: (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                    barGroups: _buildBarChartData(),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: ((totalIncome > totalExpense ? totalIncome : totalExpense) / 5)
                              .clamp(1, double.infinity),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text('Income');
                              case 1:
                                return const Text('Expense');
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text('Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              monthlyTransactions.isEmpty
                  ? const Text('No transactions this month.')
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: monthlyTransactions.length,
                itemBuilder: (context, index) {
                  final doc = monthlyTransactions[index];
                  final data = doc.data()! as Map<String, dynamic>;
                  final date = (data['timestamp'] as Timestamp).toDate();
                  final isIncome = data['type'] == 'income';

                  return ListTile(
                    leading: Icon(
                      isIncome ? Icons.attach_money : Icons.money_off,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(data['category'] ?? 'Unknown'),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    trailing: Text(
                      '${isIncome ? '+' : '-'} Rs. ${data['amount'].toString()}',
                      style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: SizedBox(
        width: 100,
        height: 80,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Rs. ${amount.toStringAsFixed(0)}',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
