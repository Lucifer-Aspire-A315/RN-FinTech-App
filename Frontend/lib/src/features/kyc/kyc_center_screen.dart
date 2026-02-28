import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:fintech_frontend/models/user_role.dart';
import 'package:fintech_frontend/src/core/auth_notifier.dart';
import 'package:fintech_frontend/src/core/kyc_repository.dart';
import 'package:fintech_frontend/src/features/kyc/kyc_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class KycCenterScreen extends ConsumerStatefulWidget {
  const KycCenterScreen({super.key});

  @override
  ConsumerState<KycCenterScreen> createState() => _KycCenterScreenState();
}

class _KycCenterScreenState extends ConsumerState<KycCenterScreen> {
  static const int _maxFileBytes = 5 * 1024 * 1024;
  bool _loading = false;
  String? _error;
  KycStatusResponse? _status;
  bool _onBehalfMode = false;
  final TextEditingController _targetSearch = TextEditingController();
  Timer? _searchDebounce;
  bool _targetSearchLoading = false;
  String? _targetSearchError;
  List<KycOnBehalfTarget> _targetResults = const <KycOnBehalfTarget>[];
  KycOnBehalfTarget? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _targetSearch.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ref.read(kycRepositoryProvider).getStatus();
      if (!mounted) return;
      setState(() => _status = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _contentTypeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  KycStatusDocument? _docByType(String type) {
    final docs = _status?.documents ?? const <KycStatusDocument>[];
    for (final d in docs) {
      if (d.type == type) return d;
    }
    return null;
  }

  void _toggleOnBehalf(bool enabled) {
    setState(() {
      _onBehalfMode = enabled;
      if (!enabled) {
        _selectedTarget = null;
        _targetResults = const <KycOnBehalfTarget>[];
        _targetSearchError = null;
        _targetSearch.clear();
      }
    });
  }

  void _onTargetSearchChanged(String value) {
    if (_selectedTarget != null && value.trim() != _selectedTarget!.name) {
      setState(() => _selectedTarget = null);
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchTargets(value.trim());
    });
  }

  Future<void> _searchTargets(String query) async {
    if (!_onBehalfMode) return;
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _targetResults = const <KycOnBehalfTarget>[];
        _targetSearchError = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _targetSearchLoading = true;
      _targetSearchError = null;
    });
    try {
      final users = await ref.read(kycRepositoryProvider).searchOnBehalfUsers(
            search: query,
            limit: 15,
          );
      if (!mounted) return;
      setState(() => _targetResults = users);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _targetSearchError = e.toString().replaceFirst('Exception: ', '');
        _targetResults = const <KycOnBehalfTarget>[];
      });
    } finally {
      if (mounted) setState(() => _targetSearchLoading = false);
    }
  }

  Future<void> _uploadDocument(KycRequiredDocument doc) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final file = (picked != null && picked.files.isNotEmpty) ? picked.files.first : null;
      if (file == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Unable to read selected file. Try another file.');
      }
      if (bytes.length > _maxFileBytes) {
        throw Exception('File exceeds 5MB limit. Select a smaller file.');
      }

      final repo = ref.read(kycRepositoryProvider);
      final targetUserId = _onBehalfMode ? _selectedTarget?.id : null;
      if (_onBehalfMode && (targetUserId == null || targetUserId.isEmpty)) {
        throw Exception('Select a target user for on-behalf upload');
      }

      final uploadReq = await repo.createUploadRequest(
        docType: doc.type,
        targetUserId: targetUserId,
      );
      final uploaded = await repo.uploadToCloudinary(
        request: uploadReq,
        bytes: bytes,
        filename: file.name,
      );

      final publicId = uploaded['public_id']?.toString() ?? uploadReq.publicId;
      final secureUrl = uploaded['secure_url']?.toString() ?? '';
      final contentType = _contentTypeFromFilename(file.name);
      final fileSize = (uploaded['bytes'] is num)
          ? (uploaded['bytes'] as num).toInt()
          : bytes.length;

      await repo.completeUpload(
        kycDocId: uploadReq.kycDocId,
        publicId: publicId,
        fileSize: fileSize,
        contentType: contentType,
        secureUrl: secureUrl,
        targetUserId: targetUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${doc.displayName} uploaded successfully')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDoc(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authNotifierProvider).user?.role ?? UserRole.unknown;
    final isBanker = role == UserRole.banker;
    final canOnBehalf =
        role == UserRole.merchant || role == UserRole.banker || role == UserRole.admin;
    final required = _status?.requiredDocuments ?? const <KycRequiredDocument>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Center'),
        actions: [
          if (isBanker)
            IconButton(
              onPressed: () => context.push('/kyc/review'),
              icon: const Icon(Icons.fact_check_rounded),
              tooltip: 'Review Queue',
            ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null)
              Card(
                child: ListTile(
                  title: const Text('KYC loading failed'),
                  subtitle: Text(_error!),
                  trailing: TextButton(onPressed: _refresh, child: const Text('Retry')),
                ),
              ),
            if (_status != null)
              Card(
                child: ListTile(
                  title: Text('Completion: ${_status!.percentComplete}%'),
                  subtitle: Text('Overall status: ${_status!.overallStatus}'),
                  leading: const Icon(Icons.verified_user_rounded),
                ),
              ),
            if (canOnBehalf) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Upload On Behalf'),
                        subtitle: const Text('Use for customer/user KYC upload by role permission'),
                        value: _onBehalfMode,
                        onChanged: _toggleOnBehalf,
                      ),
                      if (_onBehalfMode) ...[
                        TextField(
                          controller: _targetSearch,
                          onChanged: _onTargetSearchChanged,
                          decoration: InputDecoration(
                            labelText: 'Search User (name/email/phone)',
                            helperText: role == UserRole.merchant
                                ? 'Only your customers are shown'
                                : 'Customers and merchants are shown',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _targetSearchLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : (_targetSearch.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _targetSearch.clear();
                                          _searchTargets('');
                                        },
                                        icon: const Icon(Icons.clear_rounded),
                                      )
                                    : null),
                          ),
                        ),
                        if (_targetSearchError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _targetSearchError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (_selectedTarget != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              tileColor: const Color(0xFFEFF6FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: const Icon(Icons.person_rounded),
                              title: Text(_selectedTarget!.name),
                              subtitle: Text(
                                '${_selectedTarget!.email} | ${_selectedTarget!.role}',
                              ),
                              trailing: IconButton(
                                onPressed: () => setState(() => _selectedTarget = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ),
                        if (_targetResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _targetResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _targetResults[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(item.name.isNotEmpty ? item.name : item.email),
                                  subtitle: Text('${item.email} | ${item.role}'),
                                  onTap: () {
                                    setState(() {
                                      _selectedTarget = item;
                                      _targetResults = const <KycOnBehalfTarget>[];
                                      _targetSearch.text = item.name;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        if (_targetSearch.text.trim().isNotEmpty &&
                            !_targetSearchLoading &&
                            _targetResults.isEmpty &&
                            _selectedTarget == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('No matching users found. Try different search text.'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            if (required.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('No KYC documents required for this account.'),
                ),
              ),
            ...required.map((doc) {
              final existing = _docByType(doc.type);
              final status = existing?.status ?? 'NOT_SUBMITTED';
              final canOpen = (existing?.url ?? '').isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc.displayName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            _StatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Type: ${doc.type}'),
                        if (existing?.createdAt != null)
                          Text(
                            'Last upload: ${existing!.createdAt!.toLocal().toString().split('.').first}',
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _loading ? null : () => _uploadDocument(doc),
                              icon: const Icon(Icons.file_upload_rounded),
                              label: Text(existing == null ? 'Upload' : 'Re-upload'),
                            ),
                            if (canOpen)
                              OutlinedButton.icon(
                                onPressed: () => _openDoc(existing!.url!),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Open'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'VERIFIED':
        bg = const Color(0xFFD1FAE5);
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2);
        break;
      case 'PENDING':
      case 'UPLOADING':
        bg = const Color(0xFFFEF3C7);
        break;
      default:
        bg = const Color(0xFFE5E7EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
