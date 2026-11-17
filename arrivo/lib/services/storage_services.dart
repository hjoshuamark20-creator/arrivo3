import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/place.dart';
import '../models/trip.dart';

/// Settings and the onboarding flag (SharedPreferences).
class SettingsRepository {
  SettingsRepository(this._prefs);
  final SharedPreferences _prefs;

  AppSettings load() {
    final raw = _prefs.getString(AppConstants.prefsSettings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _prefs.setString(AppConstants.prefsSettings, jsonEncode(settings.toJson()));

  bool get onboardingDone => _prefs.getBool(AppConstants.prefsOnboardingDone) ?? false;

  Future<void> setOnboardingDone() => _prefs.setBool(AppConstants.prefsOnboardingDone, true);
}

/// The trip that is running right now, so it can be restored if the app is killed.
class ActiveTripSnapshot {
  const ActiveTripSnapshot({required this.trip, required this.settings});
  final Trip trip;
  final AppSettings settings;
}

class ActiveTripStore {
  ActiveTripStore(this._prefs);
  final SharedPreferences _prefs;

  Future<void> save(ActiveTripSnapshot snapshot) => _prefs.setString(
        AppConstants.prefsActiveTrip,
        jsonEncode({'trip': snapshot.trip.toMap(), 'settings': snapshot.settings.toJson()}),
      );

  ActiveTripSnapshot? read() {
    final raw = _prefs.getString(AppConstants.prefsActiveTrip);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ActiveTripSnapshot(
        trip: Trip.fromMap(Map<String, Object?>.from(map['trip'] as Map)),
        settings: AppSettings.fromJson(Map<String, dynamic>.from(map['settings'] as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _prefs.remove(AppConstants.prefsActiveTrip);
}

/// SQLite database for saved places and the trip history.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'arrivo.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE places('
          'id TEXT PRIMARY KEY, name TEXT NOT NULL, latitude REAL NOT NULL, '
          'longitude REAL NOT NULL, radius REAL NOT NULL, created_at INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE trips('
          'id TEXT PRIMARY KEY, destination_name TEXT NOT NULL, latitude REAL NOT NULL, '
          'longitude REAL NOT NULL, radius REAL NOT NULL, started_at INTEGER NOT NULL, '
          'ended_at INTEGER, status TEXT NOT NULL)',
        );
      },
    );
  }
}

class PlaceRepository {
  PlaceRepository(this._db);
  final AppDatabase _db;

  Future<List<Place>> list() async {
    final db = await _db.database;
    final rows = await db.query('places', orderBy: 'created_at DESC');
    return rows.map(Place.fromMap).toList();
  }

  Future<void> save(Place place) async {
    final db = await _db.database;
    await db.insert('places', place.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('places', where: 'id = ?', whereArgs: [id]);
  }
}

class TripRepository {
  TripRepository(this._db);
  final AppDatabase _db;

  Future<void> save(Trip trip) async {
    final db = await _db.database;
    await db.insert('trips', trip.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Trip>> recent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query('trips', orderBy: 'started_at DESC', limit: limit);
    return rows.map(Trip.fromMap).toList();
  }
}
