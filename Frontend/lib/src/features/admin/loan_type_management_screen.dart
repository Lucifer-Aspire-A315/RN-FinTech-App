import 'package:fintech_frontend/src/core/loan_repository.dart';
import 'package:fintech_frontend/src/features/loans/loan_models.dart';
import 'package:fintech_frontend/src/features/loans/loan_type_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanTypeManagementScreen extends ConsumerStatefulWidget {
  const LoanTypeManagementScreen({super.key});

  @override
  ConsumerState<LoanTypeManagementScreen> createState() =>
      _LoanTypeManagementScreenState();
}

class _LoanTypeManagementScreenState
    extends ConsumerState<LoanTypeManagementScreen> {
  bool _loading = false;
  String? _error;
  List<LoanTypeOption> _items = [];
  List<BankOption> _banks = [];

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
        repo.listLoanTypes(),
        repo.listBanks(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<LoanTypeOption>;
        _banks = results[1] as List<BankOption>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createLoanType() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final code = TextEditingController();
    final desc = TextEditingController();
    final rate = TextEditingController();
    final minTenure = TextEditingController();
    final maxTenure = TextEditingController();
    final minAmount = TextEditingController();
    final maxAmount = TextEditingController();
    final selectedBankIds = <String>{};
    String selectedTemplateKey = 'AUTO';

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Create Loan Type'),
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
                              const InputDecoration(labelText: 'Name *'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: code,
                          decoration:
                              const InputDecoration(labelText: 'Code'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: desc,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: rate,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Interest Rate % *'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final n = num.tryParse(v.trim());
                            if (n == null || n < 0 || n > 100) return '0-100';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: minTenure,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Tenure',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: maxTenure,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Tenure',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: minAmount,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Amount',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: maxAmount,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Amount',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Associate Banks',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _banks.map((b) {
                            final selected = selectedBankIds.contains(b.id);
                            return FilterChip(
                              label: Text(b.name),
                              selected: selected,
                              onSelected: (v) {
                                setDialogState(() {
                                  if (v) {
                                    selectedBankIds.add(b.id);
                                  } else {
                                    selectedBankIds.remove(b.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTemplateKey,
                          decoration: const InputDecoration(
                            labelText: 'Loan Field Template',
                            helperText: 'Auto detects by code/name, or choose explicitly',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'AUTO',
                              child: Text('Auto Detect (Recommended)'),
                            ),
                            ...loanTypeTemplates.map(
                              (t) => DropdownMenuItem<String>(
                                value: t.key,
                                child: Text('${t.label} (${t.key})'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTemplateKey = value ?? 'AUTO';
                            });
                          },
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

    LoanTypeTemplate? selectedTemplate;
    if (selectedTemplateKey == 'AUTO') {
      selectedTemplate = inferLoanTypeTemplate(
        code: code.text.trim(),
        name: name.text.trim(),
      );
    } else {
      selectedTemplate = findLoanTypeTemplateByKey(selectedTemplateKey);
    }

    try {
      await ref.read(loanRepositoryProvider).createLoanType(
            name: name.text.trim(),
            code: code.text.trim().isEmpty ? null : code.text.trim(),
            description: desc.text.trim().isEmpty ? null : desc.text.trim(),
            interestRate: num.parse(rate.text.trim()),
            minTenure: int.tryParse(minTenure.text.trim()),
            maxTenure: int.tryParse(maxTenure.text.trim()),
            minAmount: num.tryParse(minAmount.text.trim()),
            maxAmount: num.tryParse(maxAmount.text.trim()),
            bankIds: selectedBankIds.toList(),
            schema: selectedTemplate?.schema,
            requiredDocuments: selectedTemplate?.requiredDocuments,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan type created')),
      );
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteLoanType(LoanTypeOption item) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Loan Type'),
            content: Text('Delete "${item.name}"?'),
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
      await ref.read(loanRepositoryProvider).deleteLoanType(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan type deleted')),
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
        title: const Text('Loan Type Management'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createLoanType,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Loan Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_error != null)
            Card(
              child: ListTile(
                title: const Text('Failed to load loan types'),
                subtitle: Text(_error!),
              ),
            ),
          if (_items.isEmpty && !_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No loan types found'),
              ),
            ),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Code: ${item.code ?? '-'} | Interest: ${item.interestRate ?? '-'}% | Amount: ${item.minAmount ?? '-'}-${item.maxAmount ?? '-'} | Tenure: ${item.minTenure ?? '-'}-${item.maxTenure ?? '-'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteLoanType(item),
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
