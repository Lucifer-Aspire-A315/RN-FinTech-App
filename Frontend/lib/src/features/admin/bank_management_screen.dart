import 'package:fintech_frontend/src/core/loan_repository.dart';
import 'package:fintech_frontend/src/features/loans/loan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BankManagementScreen extends ConsumerStatefulWidget {
  const BankManagementScreen({super.key});

  @override
  ConsumerState<BankManagementScreen> createState() =>
      _BankManagementScreenState();
}

class _BankManagementScreenState extends ConsumerState<BankManagementScreen> {
  bool _loading = false;
  String? _error;
  List<BankOption> _banks = [];
  List<LoanTypeOption> _loanTypes = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(loanRepositoryProvider);
      final results = await Future.wait([
        repo.listBanks(),
        repo.listLoanTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _banks = results[0] as List<BankOption>;
        _loanTypes = results[1] as List<LoanTypeOption>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBank() async {
    final name = TextEditingController();
    final selectedLoanTypeIds = <String>{};
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Create Bank'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Bank Name *'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Associated Loan Types',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _loanTypes.map((lt) {
                            final selected = selectedLoanTypeIds.contains(lt.id);
                            return FilterChip(
                              label: Text(lt.name),
                              selected: selected,
                              onSelected: (v) {
                                setDialogState(() {
                                  if (v) {
                                    selectedLoanTypeIds.add(lt.id);
                                  } else {
                                    selectedLoanTypeIds.remove(lt.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await ref.read(loanRepositoryProvider).createBank(
            name: name.text.trim(),
            loanTypeIds: selectedLoanTypeIds.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank created')),
      );
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteBank(BankOption bank) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Bank'),
            content: Text('Delete "${bank.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await ref.read(loanRepositoryProvider).deleteBank(bank.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank deleted')),
      );
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Management'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBank,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bank'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_error != null)
            Card(
              child: ListTile(
                title: const Text('Failed to load banks'),
                subtitle: Text(_error!),
              ),
            ),
          if (_banks.isEmpty && !_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No banks found'),
              ),
            ),
          ..._banks.map(
            (bank) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(bank.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteBank(bank),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
