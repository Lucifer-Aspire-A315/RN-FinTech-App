import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/core/loan_repository.dart';
import 'package:fintech_frontend/src/core/upload_repository.dart';
import 'package:fintech_frontend/src/features/loans/loan_models.dart';
import 'package:fintech_frontend/src/features/loans/loan_type_templates.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ApplicantMode { self, existingCustomer, newCustomer }

class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _tenor = TextEditingController();

  final _existingCustomerId = TextEditingController();
  final _newCustomerName = TextEditingController();
  final _newCustomerEmail = TextEditingController();
  final _newCustomerPhone = TextEditingController();
  final _newCustomerAddress = TextEditingController();

  bool _loading = false;
  String? _error;
  List<LoanTypeOption> _loanTypes = [];
  String? _selectedLoanTypeId;
  _ApplicantMode _applicantMode = _ApplicantMode.self;

  final Map<String, TextEditingController> _metadataControllers = {};
  final Map<String, _UploadedLoanDocument> _uploadedDocumentsByType = {};

  @override
  void initState() {
    super.initState();
    _fetchLoanTypes();
  }

  @override
  void dispose() {
    _amount.dispose();
    _tenor.dispose();
    _existingCustomerId.dispose();
    _newCustomerName.dispose();
    _newCustomerEmail.dispose();
    _newCustomerPhone.dispose();
    _newCustomerAddress.dispose();
    for (final c in _metadataControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchLoanTypes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ref.read(loanRepositoryProvider).listLoanTypes();
      if (!mounted) return;
      setState(() {
        _loanTypes = items;
        if (_loanTypes.isNotEmpty) {
          _selectedLoanTypeId ??= _loanTypes.first.id;
          _initializeMetadataControllers(_selectedLoanType);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  LoanTypeOption? get _selectedLoanType {
    if (_selectedLoanTypeId == null) return null;
    for (final type in _loanTypes) {
      if (type.id == _selectedLoanTypeId) return type;
    }
    return null;
  }

  void _initializeMetadataControllers(LoanTypeOption? type) {
    final properties = _schemaProperties(type);
    final keys = properties.keys.toSet();

    final removeKeys = _metadataControllers.keys.where((k) => !keys.contains(k)).toList();
    for (final key in removeKeys) {
      _metadataControllers[key]?.dispose();
      _metadataControllers.remove(key);
    }

    for (final key in keys) {
      _metadataControllers.putIfAbsent(key, () => TextEditingController());
    }
  }

  Map<String, dynamic> _schemaProperties(LoanTypeOption? type) {
    if (type == null) return <String, dynamic>{};

    final effectiveSchema = _effectiveSchema(type);
    final props = effectiveSchema['properties'];
    if (props is Map) return props.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Set<String> _schemaRequiredKeys(LoanTypeOption? type) {
    if (type == null) return <String>{};
    final effectiveSchema = _effectiveSchema(type);
    final required = effectiveSchema['required'];
    if (required is List) return required.map((e) => e.toString()).toSet();
    return <String>{};
  }

  Map<String, dynamic> _effectiveSchema(LoanTypeOption type) {
    final hasBackendSchema = type.schema['properties'] is Map &&
        (type.schema['properties'] as Map).isNotEmpty;
    if (hasBackendSchema) return type.schema;

    final template = inferLoanTypeTemplate(loanType: type);
    if (template != null) return template.schema;
    return type.schema;
  }

  List<String> _effectiveRequiredDocuments(LoanTypeOption type) {
    if (type.requiredDocuments.isNotEmpty) return type.requiredDocuments;
    final template = inferLoanTypeTemplate(loanType: type);
    if (template != null) return template.requiredDocuments;
    return const <String>[];
  }

  String _toLabel(String key) {
    if (key.isEmpty) return key;
    final withSpaces = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}');
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }

  Map<String, dynamic>? _buildApplicantPayload(UserRole role) {
    if (role == UserRole.customer) return null;
    if (role != UserRole.merchant) return null;

    if (_applicantMode == _ApplicantMode.self) {
      return {'type': 'merchant'};
    }
    if (_applicantMode == _ApplicantMode.existingCustomer) {
      return {
        'type': 'existing',
        'customerId': _existingCustomerId.text.trim(),
      };
    }
    return {
      'type': 'new',
      'customer': {
        'name': _newCustomerName.text.trim(),
        'email': _newCustomerEmail.text.trim(),
        'phone': _newCustomerPhone.text.trim(),
        'address': _newCustomerAddress.text.trim(),
      },
    };
  }

  Map<String, dynamic> _buildMetadataPayload() {
    final props = _schemaProperties(_selectedLoanType);
    final payload = <String, dynamic>{};

    for (final entry in props.entries) {
      final key = entry.key;
      final schema = entry.value is Map
          ? (entry.value as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final type = schema['type']?.toString();
      final raw = _metadataControllers[key]?.text.trim() ?? '';
      if (raw.isEmpty) continue;

      if (type == 'number') {
        final v = num.tryParse(raw);
        if (v != null) payload[key] = v;
      } else if (type == 'integer') {
        final v = int.tryParse(raw);
        if (v != null) payload[key] = v;
      } else if (type == 'boolean') {
        payload[key] = raw.toLowerCase() == 'true';
      } else {
        payload[key] = raw;
      }
    }

    return payload;
  }

  String _contentTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );

      final picked = (result != null && result.files.isNotEmpty) ? result.files.first : null;
      if (picked == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to read file bytes. Please pick a smaller file and retry.');
      }

      final uploadRepo = ref.read(uploadRepositoryProvider);
      final signature = await uploadRepo.getSignature(
        folder: 'loan-documents',
        filename: picked.name,
      );
      final uploaded = await uploadRepo.uploadToCloudinary(
        signature: signature,
        bytes: bytes,
        filename: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _uploadedDocumentsByType[docType] = _UploadedLoanDocument(
          type: docType,
          publicId: uploaded.publicId,
          secureUrl: uploaded.secureUrl,
          filename: picked.name,
          fileType: _contentTypeFromFilename(picked.name),
          bytes: uploaded.bytes > 0 ? uploaded.bytes : bytes.length,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$docType uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _buildLoanDocumentsPayload() {
    return _uploadedDocumentsByType.values
        .map(
          (doc) => <String, dynamic>{
            'type': doc.type,
            'public_id': doc.publicId,
            'secure_url': doc.secureUrl,
            'filename': doc.filename,
            'fileType': doc.fileType,
            'bytes': doc.bytes,
          },
        )
        .toList();
  }

  Future<void> _submit(UserRole role) async {
    if (!_formKey.currentState!.validate()) return;
    final type = _selectedLoanType;
    if (type == null) {
      setState(() => _error = 'Loan type is required');
      return;
    }

    final amount = num.tryParse(_amount.text.trim());
    final tenor = int.tryParse(_tenor.text.trim());
    if (amount == null) {
      setState(() => _error = 'Invalid amount');
      return;
    }

    if (type.minAmount != null && amount < type.minAmount!) {
      setState(() => _error = 'Amount must be at least ${type.minAmount}');
      return;
    }
    if (type.maxAmount != null && amount > type.maxAmount!) {
      setState(() => _error = 'Amount cannot exceed ${type.maxAmount}');
      return;
    }
    if (tenor != null && type.minTenure != null && tenor < type.minTenure!) {
      setState(() => _error = 'Tenor must be at least ${type.minTenure} months');
      return;
    }
    if (tenor != null && type.maxTenure != null && tenor > type.maxTenure!) {
      setState(() => _error = 'Tenor cannot exceed ${type.maxTenure} months');
      return;
    }

    final requiredKeys = _schemaRequiredKeys(type);
    for (final key in requiredKeys) {
      final value = _metadataControllers[key]?.text.trim() ?? '';
      if (value.isEmpty) {
        setState(() => _error = '${_toLabel(key)} is required for this loan type');
        return;
      }
    }

    final requiredDocs = _effectiveRequiredDocuments(type);
    final missingDocs = requiredDocs
        .where((d) => !_uploadedDocumentsByType.containsKey(d))
        .toList();
    if (missingDocs.isNotEmpty) {
      setState(() => _error = 'Upload required documents: ${missingDocs.join(', ')}');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(loanRepositoryProvider).applyLoan(
            loanTypeId: type.id,
            amount: amount,
            tenorMonths: tenor,
            applicant: _buildApplicantPayload(role),
            metadata: _buildMetadataPayload(),
            documents: _buildLoanDocumentsPayload(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan application submitted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authNotifierProvider).user?.role ?? UserRole.unknown;
    final canApply = role == UserRole.merchant || role == UserRole.customer;
    final isMerchant = role == UserRole.merchant;

    final selectedType = _selectedLoanType;
    final schemaProps = _schemaProperties(selectedType);
    final requiredKeys = _schemaRequiredKeys(selectedType);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply Loan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canApply)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Only merchant or customer accounts can apply for loans.'),
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_loading) const LinearProgressIndicator(minHeight: 3),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLoanTypeId,
                    decoration: const InputDecoration(labelText: 'Loan Type'),
                    items: _loanTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type.id,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedLoanTypeId = v;
                        _initializeMetadataControllers(_selectedLoanType);
                        _uploadedDocumentsByType.clear();
                      });
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  if (selectedType != null && (selectedType.description?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        selectedType.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = num.tryParse(v.trim());
                      if (n == null) return 'Invalid number';
                      if (n < 1000) return 'Minimum is 1000';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tenor,
                    decoration: const InputDecoration(labelText: 'Tenor (months, optional)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Invalid tenor';
                      return null;
                    },
                  ),
                  if (schemaProps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Loan Details', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    ...schemaProps.entries.map((entry) {
                      final key = entry.key;
                      final fieldSchema = entry.value is Map
                          ? (entry.value as Map).cast<String, dynamic>()
                          : <String, dynamic>{};
                      final type = fieldSchema['type']?.toString();
                      final description = fieldSchema['description']?.toString();
                      final isRequired = requiredKeys.contains(key);

                      TextInputType keyboardType = TextInputType.text;
                      if (type == 'number' || type == 'integer') {
                        keyboardType = TextInputType.number;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: _metadataControllers[key],
                          keyboardType: keyboardType,
                          decoration: InputDecoration(
                            labelText: '${_toLabel(key)}${isRequired ? ' *' : ''}',
                            helperText: description,
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (isRequired && value.isEmpty) return 'Required';
                            if (value.isEmpty) return null;
                            if (type == 'number' && num.tryParse(value) == null) return 'Must be a number';
                            if (type == 'integer' && int.tryParse(value) == null) return 'Must be an integer';
                            if (type == 'boolean' &&
                                !['true', 'false'].contains(value.toLowerCase())) {
                              return 'Use true or false';
                            }
                            return null;
                          },
                        ),
                      );
                    }),
                  ],
                  if (selectedType != null && _effectiveRequiredDocuments(selectedType).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Required Documents'),
                            const SizedBox(height: 8),
                            ..._effectiveRequiredDocuments(selectedType).map((d) {
                              final uploaded = _uploadedDocumentsByType[d];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        uploaded == null ? d : '$d (${uploaded.filename})',
                                        style: TextStyle(
                                          color: uploaded == null ? null : Colors.green.shade700,
                                          fontWeight: uploaded == null ? FontWeight.w500 : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _loading ? null : () => _pickAndUploadDocument(d),
                                      icon: const Icon(Icons.file_upload_rounded),
                                      label: Text(uploaded == null ? 'Upload' : 'Replace'),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (isMerchant) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Applicant', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Myself'),
                          selected: _applicantMode == _ApplicantMode.self,
                          onSelected: (_) => setState(() => _applicantMode = _ApplicantMode.self),
                        ),
                        ChoiceChip(
                          label: const Text('Existing Customer'),
                          selected: _applicantMode == _ApplicantMode.existingCustomer,
                          onSelected: (_) =>
                              setState(() => _applicantMode = _ApplicantMode.existingCustomer),
                        ),
                        ChoiceChip(
                          label: const Text('New Customer'),
                          selected: _applicantMode == _ApplicantMode.newCustomer,
                          onSelected: (_) => setState(() => _applicantMode = _ApplicantMode.newCustomer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_applicantMode == _ApplicantMode.existingCustomer)
                      TextFormField(
                        controller: _existingCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Existing Customer ID',
                          helperText: 'Enter customer user ID',
                        ),
                        validator: (v) {
                          if (_applicantMode != _ApplicantMode.existingCustomer) return null;
                          if (v == null || v.trim().isEmpty) return 'Customer ID is required';
                          return null;
                        },
                      ),
                    if (_applicantMode == _ApplicantMode.newCustomer) ...[
                      TextFormField(
                        controller: _newCustomerName,
                        decoration: const InputDecoration(labelText: 'Customer Name'),
                        validator: (v) {
                          if (_applicantMode != _ApplicantMode.newCustomer) return null;
                          if (v == null || v.trim().isEmpty) return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newCustomerEmail,
                        decoration: const InputDecoration(labelText: 'Customer Email'),
                        validator: (v) {
                          if (_applicantMode != _ApplicantMode.newCustomer) return null;
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                          return ok ? null : 'Invalid email';
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newCustomerPhone,
                        decoration: const InputDecoration(labelText: 'Customer Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (_applicantMode != _ApplicantMode.newCustomer) return null;
                          if (v == null || v.trim().isEmpty) return 'Phone is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newCustomerAddress,
                        decoration: const InputDecoration(labelText: 'Customer Address (optional)'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : () => _submit(role),
                      child: const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadedLoanDocument {
  final String type;
  final String publicId;
  final String secureUrl;
  final String filename;
  final String fileType;
  final int bytes;

  const _UploadedLoanDocument({
    required this.type,
    required this.publicId,
    required this.secureUrl,
    required this.filename,
    required this.fileType,
    required this.bytes,
  });
}
