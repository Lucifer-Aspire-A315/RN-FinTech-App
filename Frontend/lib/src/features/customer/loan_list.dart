import 'package:flutter/material.dart';

class LoanList extends StatelessWidget {
  const LoanList({super.key});

  @override
  Widget build(BuildContext context) {
    final demoLoans = [
      {'id': 'L1', 'amount': 50000, 'status': 'PENDING'},
      {'id': 'L2', 'amount': 200000, 'status': 'APPROVED'},
    ];

    return ListView.builder(
      itemCount: demoLoans.length,
      itemBuilder: (context, i) {
        final item = demoLoans[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('Loan ${item['id']}'),
            subtitle: Text('Rs ${item['amount']} | ${item['status']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}
