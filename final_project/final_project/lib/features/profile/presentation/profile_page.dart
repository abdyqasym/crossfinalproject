import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/providers/car_detail_providers.dart';
import '../model/profile_model.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = ProfileModel(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved locally')),
    );
  }

  Future<void> _clearProfile() async {
    await ref.read(profileProvider.notifier).clearProfile();
    if (!mounted) return;
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local profile cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final lastViewedCarState = ref.watch(lastViewedCarProvider);
    final currentUser = ref.watch(currentUserProvider);

    profileState.whenData((profile) {
      if (!_initialized) {
        _initialized = true;
        _nameCtrl.text = profile?.name ?? '';
        _emailCtrl.text = profile?.email ?? currentUser?.email ?? '';
        _phoneCtrl.text = profile?.phone ?? '';
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal details',
                  style: TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                currentUser?.email != null
                    ? 'Signed in as ${currentUser!.email}'
                    : 'Working offline with local profile',
                style: const TextStyle(
                    color: AppTheme.textMed, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _InputField(
                      controller: _nameCtrl,
                      label: 'Full name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _emailCtrl,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _phoneCtrl,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text('Save profile locally'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _clearProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textHigh,
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              const Text('Last viewed car',
                  style: TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              lastViewedCarState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                  ),
                ),
                error: (_, __) => const Text(
                  'Unable to load last viewed car.',
                  style: TextStyle(color: AppTheme.textMed),
                ),
                data: (car) {
                  if (car == null) {
                    return const Text(
                      'Open a car detail page to save it locally.',
                      style: TextStyle(color: AppTheme.textMed),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(car.displayName,
                            style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(car.formattedPrice,
                            style: const TextStyle(
                                color: AppTheme.textHigh,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('${car.fuelType} • ${car.transmission} • ${car.condition}',
                            style: const TextStyle(
                                color: AppTheme.textMed, fontSize: 13)),
                        const SizedBox(height: 12),
                        Text(car.description ?? 'No description available.',
                            style: const TextStyle(
                                color: AppTheme.textHigh, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textHigh),
      decoration: InputDecoration(labelText: label),
    );
  }
}
