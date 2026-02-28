import 'package:fintech_frontend/src/core/kyc_repository.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/features/kyc/kyc_models.dart';
import 'package:fintech_frontend/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class KycReviewScreen extends ConsumerStatefulWidget {
  const KycReviewScreen({super.key});

  @override
  ConsumerState<KycReviewScreen> createState() => _KycReviewScreenState();
}

class _KycReviewScreenState extends ConsumerState<KycReviewScreen> {
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;
  List<KycPendingItem> _items = const <KycPendingItem>[];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(kycRepositoryProvider).getPendingForReview(limit: 50);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _review(KycPendingItem item) async {
    final notesController = TextEditingController();
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review KYC Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applicant: ${item.userName ?? '-'}'),
            Text('Role: ${item.userRole ?? '-'}'),
            Text('Type: ${item.type}'),
            Text('Pending: ${item.daysPending} days'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (required for reject)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'REJECT'),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'APPROVE'),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (decision == null) return;
    final notes = notesController.text.trim();
    if (decision == 'REJECT' && notes.isEmpty) {
      _showMessage('Rejection notes are required.');
      return;
    }

    setState(() => _actionLoading = true);
    try {
      await ref.read(kycRepositoryProvider).verifyDocument(
            kycDocId: item.id,
            approved: decision == 'APPROVE',
            notes: notes,
          );
      if (!mounted) return;
      _showMessage(decision == 'APPROVE' ? 'KYC verified' : 'KYC rejected');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authNotifierProvider).user?.role ?? UserRole.unknown;
    if (role != UserRole.banker) {
      return Scaffold(
        appBar: AppBar(title: const Text('KYC Review Queue')),
        body: const Center(
          child: Text('Only banker accounts can review KYC documents.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Review Queue'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_actionLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_error != null)
              Card(
                child: ListTile(
                  title: const Text('Failed to load queue'),
                  subtitle: Text(_error!),
                  trailing: TextButton(onPressed: _refresh, child: const Text('Retry')),
                ),
              ),
            if (_items.isEmpty && !_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('No pending KYC documents found.'),
                ),
              ),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.userName ?? 'Unknown User',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('Type: ${item.type}'),
                        Text('Role: ${item.userRole ?? '-'}'),
                        Text('Pending: ${item.daysPending} days'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if ((item.url ?? '').isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _open(item.url!),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Open Document'),
                              ),
                            FilledButton.icon(
                              onPressed: _actionLoading ? null : () => _review(item),
                              icon: const Icon(Icons.fact_check_rounded),
                              label: const Text('Review'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
