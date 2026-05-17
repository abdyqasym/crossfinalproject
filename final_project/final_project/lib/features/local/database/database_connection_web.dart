// Используем WebDatabase — помечаем использование как experimental
// чтобы подавить предупреждение анализатора о экспериментальной API.
// ignore_for_file: experimental_member_use

import 'package:drift/web.dart' show WebDatabase;
import 'package:drift/drift.dart';

LazyDatabase openDatabaseConnection() => LazyDatabase(() async => WebDatabase('autovault.db'));
