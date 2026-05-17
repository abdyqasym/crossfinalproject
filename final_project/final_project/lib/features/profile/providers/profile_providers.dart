import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/features/local/providers/local_database_provider.dart';
import 'package:car_buying_app/features/profile/model/profile_model.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(
  () => ProfileNotifier(),
);

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  late final AppDatabase _db;

  @override
  Future<ProfileModel?> build() async {
    _db = ref.watch(appDatabaseProvider);
    return _db.getProfileModel();
  }

  Future<void> saveProfile(ProfileModel profile) async {
    state = const AsyncValue.loading();
    await _db.upsertProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> clearProfile() async {
    state = const AsyncValue.loading();
    await _db.clearProfile();
    state = const AsyncValue.data(null);
  }
}
