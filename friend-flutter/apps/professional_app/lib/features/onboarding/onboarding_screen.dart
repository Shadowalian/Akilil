import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:friend_professional/l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:core/core.dart';

/// Pro onboarding wizard. v1 surfaces the steps required to
/// start accepting bookings: profile basics, category + headline,
/// rate, verification documents. Each step submits to the relevant API,
/// then advances. Skipped steps are still flagged on the
/// dashboard "nudge" card so they can be finished later.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _S();
}

const _lastStep = 4;

class _S extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _busy = false;
  String? _error;

  // Step state.
  final _headline = TextEditingController();
  final _bio      = TextEditingController();
  final _rate     = TextEditingController(text: '50');
  String _category = AkililPillars.defaultSlug;
  String _docType  = 'professional_license';
  final _uploaded  = <String>[];

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // The document and confirmation steps have nothing to persist here:
    // uploads submit on their own, and the last step just exits the wizard.
    if (_step >= 3) {
      if (_step == _lastStep) {
        context.go('/');
      } else {
        setState(() { _step = _lastStep; _error = null; });
      }
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/me/professional-profile', data: {
        'bio': _bio.text.trim().isEmpty
            ? _headline.text.trim()
            : _bio.text.trim(),
        'category_id': _category,
        'hourly_rate_cents': (int.tryParse(_rate.text) ?? 0) * 100,
        'is_accepting_clients': true,
      });
      if (mounted) setState(() => _step = (_step + 1).clamp(0, _lastStep));
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? ((e.response!.data['message'] ?? tr('Save failed')) as String)
            : tr('Save failed.');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Picks an image of a credential and uploads it as multipart.
  /// The API also accepts PDFs, but the gallery picker only yields images.
  Future<void> _uploadDocument() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(dioProvider).post(
        '/professionals/onboarding/documents',
        data: FormData.fromMap({
          'document_type': _docType,
          'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
        }),
      );
      if (mounted) setState(() => _uploaded.add(picked.name));
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? ((e.response!.data['message'] ?? tr('Upload failed')) as String)
            : tr('Upload failed.');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Set up your practice')),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_step + 1) / (_lastStep + 1)),
            const SizedBox(height: 24),
            Expanded(child: _buildStep()),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_step == _lastStep ? 'Finish' : tr('Continue')),
            ),
            if (_step < _lastStep)
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(tr('Finish later')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Tell clients about yourself'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _headline,
            decoration: InputDecoration(
              labelText: tr('Headline'),
              hintText: tr('Compassionate listener • 5 yrs'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            minLines: 4, maxLines: 8,
            decoration: InputDecoration(
              labelText: tr('About you'),
              alignLabelWithHint: true,
            ),
          ),
        ]),
      1 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Choose your Akilil practice'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            tr('You can only practice in one of these three pillars.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FriendColors.textSecondary,
                ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: FriendPillarPicker(
                selectedSlug: _category,
                onSelected: (slug) => setState(
                  () => _category = slug ?? AkililPillars.defaultSlug,
                ),
              ),
            ),
          ),
        ]),
      2 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Set your rate'), style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          Text(
            tr('You can change this anytime. Akilil takes a 15% service fee on the platform total.'),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _rate,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr('Hourly rate (USD)'),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
        ]),
      3 => ListView(children: [
          Text(tr('Verify your credentials'), style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          Text(
            tr('Upload a licence, degree or ID so we can verify you. '
                'You can skip this and add it later from your profile.'),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _docType,
            decoration: InputDecoration(labelText: tr('Document type')),
            items: [
              DropdownMenuItem(value: 'professional_license', child: Text(tr('Professional licence'))),
              DropdownMenuItem(value: 'government_id', child: Text(tr('Government ID'))),
              DropdownMenuItem(value: 'degree', child: Text(tr('Degree'))),
              DropdownMenuItem(value: 'certification', child: Text(tr('Certification'))),
              DropdownMenuItem(value: 'background_check', child: Text(tr('Background check'))),
              DropdownMenuItem(value: 'other', child: Text(tr('Other'))),
            ],
            onChanged: (v) => setState(() => _docType = v ?? 'professional_license'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _uploadDocument,
            icon: const Icon(Icons.upload_file),
            label: Text(tr('Choose a file')),
          ),
          const SizedBox(height: 8),
          Text(
            tr('JPG or PNG, up to 10 MB.'),
            style: TextStyle(color: FriendColors.textSecondary),
          ),
          for (final name in _uploaded)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: FriendColors.primary),
              title: Text(name, overflow: TextOverflow.ellipsis),
              subtitle: Text(tr('In review')),
            ),
        ]),
      _ => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.check_circle, size: 64, color: FriendColors.primary),
          const SizedBox(height: 16),
          Text(tr('You\'re ready'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            tr('Your profile is in review. We\'ll let you know within 48 hours when you can start accepting bookings.'),
          ),
        ]),
    };
  }
}