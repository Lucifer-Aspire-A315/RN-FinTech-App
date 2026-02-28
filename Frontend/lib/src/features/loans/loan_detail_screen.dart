import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/core/loan_repository.dart';
import 'package:fintech_frontend/src/core/upload_repository.dart';
import 'package:fintech_frontend/src/features/loans/loan_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  static const int _maxUploadBytes = 10 * 1024 * 1024;
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;
  LoanSummary? _loan;

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
      final loan = await ref.read(loanRepositoryProvider).getLoan(widget.loanId);
      if (!mounted) return;
      setState(() => _loan = loan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelLoan() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel loan?'),
            content: const Text('This action will mark the loan as CANCELLED.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(loanRepositoryProvider).cancelLoan(widget.loanId, reason: 'Cancelled from app');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan cancelled successfully')),
      );
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _requestAssignment() async {
    final noteController = TextEditingController();
    final rateController = TextEditingController();
    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Proposed Interest Rate (%)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Why you are a good fit for this case',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'rate': rateController.text.trim(),
              'note': noteController.text.trim(),
            }),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (data == null) return;
    final proposedRate = num.tryParse(data['rate'] ?? '');
    if (proposedRate == null || proposedRate <= 0) {
      _showError('Enter valid proposed interest rate');
      return;
    }
    final note = data['note'];

    await _runAction(() async {
      await ref.read(loanRepositoryProvider).requestAssignment(
            id: widget.loanId,
            note: note,
            proposedInterestRate: proposedRate,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment request sent')),
      );
      _fetch();
    });
  }

  Future<void> _assignmentDecision(String bankerId, bool approve) async {
    final notesController = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Assignment?' : 'Reject Assignment?'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: approve ? 'Notes (optional)' : 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim()),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (notes == null) return;
    await _runAction(() async {
      await ref.read(loanRepositoryProvider).assignmentDecision(
            id: widget.loanId,
            bankerId: bankerId,
            approve: approve,
            notes: notes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Assignment approved' : 'Assignment rejected')),
      );
      _fetch();
    });
  }

  Future<void> _assignById() async {
    final bankerId = await _pickBankerForAssignment();
    if (bankerId == null || bankerId.isEmpty) return;

    await _runAction(() async {
      await ref.read(loanRepositoryProvider).assignBanker(
            id: widget.loanId,
            bankerId: bankerId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banker assigned successfully')),
      );
      _fetch();
    });
  }

  Future<String?> _pickBankerForAssignment() async {
    setState(() => _actionLoading = true);
    List<BankerOption> bankers = [];
    try {
      bankers = await ref.read(loanRepositoryProvider).listBankers();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      return null;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }

    if (bankers.isEmpty) {
      _showError('No active bankers found');
      return null;
    }
    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Banker'),
        content: SizedBox(
          width: 420,
          height: 340,
          child: ListView.separated(
            itemCount: bankers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final banker = bankers[index];
              return ListTile(
                title: Text(banker.name),
                subtitle: Text(banker.email),
                onTap: () => Navigator.pop(context, banker.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveLoan() async {
    final notesController = TextEditingController();

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Loan'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, notesController.text.trim());
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (notes == null) return;

    await _runAction(() async {
      await ref.read(loanRepositoryProvider).approveLoan(
            id: widget.loanId,
            notes: notes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan approved successfully')),
      );
      _fetch();
    });
  }

  Future<void> _rejectLoan() async {
    final notesController = TextEditingController();

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Loan'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Rejection reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (notes == null || notes.isEmpty) {
      _showError('Rejection reason is required');
      return;
    }

    await _runAction(() async {
      await ref.read(loanRepositoryProvider).rejectLoan(
            id: widget.loanId,
            notes: notes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan rejected')),
      );
      _fetch();
    });
  }

  Future<void> _disburseLoan() async {
    final refController = TextEditingController();
    final notesController = TextEditingController();

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disburse Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refController,
              decoration: const InputDecoration(labelText: 'Reference ID'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'referenceId': refController.text.trim(),
                'notes': notesController.text.trim(),
              });
            },
            child: const Text('Disburse'),
          ),
        ],
      ),
    );

    if (data == null) return;
    final referenceId = data['referenceId'] ?? '';
    if (referenceId.isEmpty) {
      _showError('Reference ID is required');
      return;
    }

    await _runAction(() async {
      await ref.read(loanRepositoryProvider).disburseLoan(
            id: widget.loanId,
            referenceId: referenceId,
            notes: data['notes'],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan disbursed successfully')),
      );
      _fetch();
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      await action();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDocumentUrl(String? rawUrl) async {
    final uri = Uri.tryParse(rawUrl ?? '');
    if (uri == null) {
      _showError('Invalid document URL');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showError('Failed to open document');
  }

  String _contentTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  Future<void> _uploadAndRegisterLoanDocument() async {
    final typeController = TextEditingController(text: 'attachment');

    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Type'),
        content: TextField(
          controller: typeController,
          decoration: const InputDecoration(
            labelText: 'Type',
            helperText: 'Examples: ID_PROOF, PAN_CARD, invoice, attachment',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, typeController.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (type == null || type.isEmpty) return;

    setState(() => _actionLoading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final file = (picked != null && picked.files.isNotEmpty) ? picked.files.first : null;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Unable to read file');
      }
      if (bytes.length > _maxUploadBytes) {
        throw Exception('File exceeds 10MB limit. Please upload a smaller file.');
      }

      final uploadRepo = ref.read(uploadRepositoryProvider);
      final sign = await uploadRepo.getSignature(
        folder: 'loan-documents',
        filename: file.name,
      );
      final uploaded = await uploadRepo.uploadToCloudinary(
        signature: sign,
        bytes: bytes,
        filename: file.name,
      );

      await uploadRepo.registerLoanDocument(
        loanId: widget.loanId,
        publicId: uploaded.publicId,
        secureUrl: uploaded.secureUrl,
        filename: file.name,
        fileType: _contentTypeFromFilename(file.name),
        bytes: uploaded.bytes > 0 ? uploaded.bytes : bytes.length,
        type: type,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded and attached to loan')),
      );
      await _fetch();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authNotifierProvider).user?.role ?? UserRole.unknown;
    final userId = ref.watch(authNotifierProvider).user?.id ?? '';
    final loan = _loan;
    final assignmentRequests = loan?.metadata['assignmentRequests'] is List
        ? (loan!.metadata['assignmentRequests'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];
    final pendingRequests =
        assignmentRequests.where((r) => (r['status']?.toString() ?? '') == 'PENDING').toList();
    final hasPendingRequest = pendingRequests.isNotEmpty;
    final hasMyPendingRequest = pendingRequests.any((r) => r['bankerId']?.toString() == userId);
    final userOwnsLoan = loan != null && (loan.applicantId == userId || loan.merchantId == userId);

    final cancellableStatuses = {'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED'};
    final canCancel = loan != null &&
        cancellableStatuses.contains(loan.status) &&
        (role == UserRole.customer || role == UserRole.merchant);
    final canAssignAsAdmin = loan != null &&
        role == UserRole.admin &&
        (loan.status == 'SUBMITTED' || loan.status == 'UNDER_REVIEW');
    final canRequestAssignment = loan != null &&
        role == UserRole.banker &&
        (loan.status == 'SUBMITTED' || loan.status == 'UNDER_REVIEW') &&
        (loan.bankerId == null) &&
        !hasMyPendingRequest;
    final canDecideAssignment = loan != null &&
        hasPendingRequest &&
        userOwnsLoan &&
        (role == UserRole.customer || role == UserRole.merchant || role == UserRole.admin);
    final canApproveReject = loan != null &&
        role == UserRole.banker &&
        loan.status == 'UNDER_REVIEW';
    final canDisburse = loan != null &&
        role == UserRole.banker &&
        loan.status == 'APPROVED';
    final canUploadDocs = loan != null &&
        (role == UserRole.customer ||
            role == UserRole.merchant ||
            role == UserRole.banker ||
            role == UserRole.admin);

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_actionLoading) const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 3),
          ),
          if (_error != null)
            Card(
              child: ListTile(
                title: const Text('Failed to load loan detail'),
                subtitle: Text(_error!),
                trailing: TextButton(onPressed: _fetch, child: const Text('Retry')),
              ),
            ),
          if (loan != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loan ID', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    SelectableText(loan.id),
                    const SizedBox(height: 10),
                    Text('Type: ${loan.loanTypeName ?? '-'}'),
                    Text('Amount: Rs ${loan.amount.toStringAsFixed(0)}'),
                    Text('Status: ${loan.status.replaceAll('_', ' ')}'),
                    Text('Applicant: ${loan.applicantName ?? '-'}'),
                    Text('Merchant: ${loan.merchantName ?? '-'}'),
                    Text('Banker: ${loan.bankerName ?? '-'}'),
                    Text('Created: ${loan.createdAt?.toLocal().toString().split('.').first ?? '-'}'),
                    if (assignmentRequests.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Assignment Requests',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...assignmentRequests.map((r) {
                        final banker = r['bankerName']?.toString() ?? r['bankerId']?.toString() ?? '-';
                        final status = r['status']?.toString() ?? '-';
                        final rate = r['proposedInterestRate']?.toString() ?? '-';
                        final note = r['note']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$banker | $status | Rate: $rate%${note.isNotEmpty ? ' | $note' : ''}',
                          ),
                        );
                      }),
                    ],
                    if (loan.documents.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Submitted Documents',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      ...loan.documents.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${d.type}${(d.filename ?? '').isNotEmpty ? ' - ${d.filename}' : ''}'
                                  '${(d.fileType ?? '').isNotEmpty ? ' (${d.fileType})' : ''}'
                                  '${d.createdAt != null ? ' | ${d.createdAt!.toLocal().toString().split('.').first}' : ''}',
                                ),
                              ),
                              if ((d.url ?? '').isNotEmpty)
                                TextButton(
                                  onPressed: () => _openDocumentUrl(d.url),
                                  child: const Text('Open'),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            if (canCancel) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _actionLoading ? null : _cancelLoan,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Loan'),
              ),
            ],
            if (canRequestAssignment) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _actionLoading ? null : _requestAssignment,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Request Assignment'),
              ),
            ],
            if (canAssignAsAdmin) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _actionLoading ? null : _assignById,
                icon: const Icon(Icons.person_search_rounded),
                label: const Text('Assign Banker (Admin)'),
              ),
            ],
            if (canDecideAssignment) ...[
              const SizedBox(height: 10),
              ...pendingRequests.map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Text(
                        'Request: ${req['bankerName'] ?? req['bankerId']} (${req['proposedInterestRate'] ?? '-' }%)',
                      ),
                      FilledButton.icon(
                        onPressed: _actionLoading
                            ? null
                            : () => _assignmentDecision(req['bankerId']?.toString() ?? '', true),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Approve'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _actionLoading
                            ? null
                            : () => _assignmentDecision(req['bankerId']?.toString() ?? '', false),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (canApproveReject) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _actionLoading ? null : _approveLoan,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Approve'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _actionLoading ? null : _rejectLoan,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
            if (canDisburse) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _actionLoading ? null : _disburseLoan,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Disburse Loan'),
              ),
            ],
            if (canUploadDocs) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _actionLoading ? null : _uploadAndRegisterLoanDocument,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Loan Document'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
