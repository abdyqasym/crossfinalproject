import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/features/local/database/app_database.dart';
export 'package:car_buying_app/features/local/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
	final db = AppDatabase();
	ref.onDispose(() => db.close());
	return db;
});
