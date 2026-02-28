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
  bool _loading = false;
  String? _error;
  KycStatusResponse? _status;

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

      final repo = ref.read(kycRepositoryProvider);
      final uploadReq = await repo.createUploadRequest(docType: doc.type);
      final uploaded = await repo.uploadToCloudinary(
        request: uploadReq,
        bytes: bytes,
        filename: file.name,
      );

      final publicId = uploaded['public_id']?.toString() ?? uploadReq.publicId;
      final contentType = _contentTypeFromFilename(file.name);
      final fileSize = (uploaded['bytes'] is num)
          ? (uploaded['bytes'] as num).toInt()
          : bytes.length;

      await repo.completeUpload(
        kycDocId: uploadReq.kycDocId,
        publicId: publicId,
        fileSize: fileSize,
        contentType: contentType,
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
