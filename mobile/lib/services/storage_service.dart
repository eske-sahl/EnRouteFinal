import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  SharedPreferences? _prefs;

  static const String keyPassengers = 'sbk_passengers_v1';
  static const String keyOwners = 'sbk_owners_v1';
  static const String keyConductors = 'sbk_conductors_v1';
  static const String keyBuses = 'sbk_buses_v1';
  static const String keyTickets = 'sbk_tickets_v1';
  static const String keyTransactions = 'sbk_transactions_v1';
  static const String keyReviews = 'sbk_reviews_v1';
  static const String keyExpenses = 'sbk_expenses_v1';
  static const String keyLostItems = 'sbk_lost_items_v1';
  static const String keyHasSeenSplash = 'sbk_has_seen_splash_v1';
  static const String keyUserSession = 'sbk_user_session_v1';
  static const String keyCustomServerUrl = 'sbk_custom_server_url_v1';

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('StorageService init error (fallback to in-memory): $e');
    }
  }

  // Generic List Loader
  List<Map<String, dynamic>>? loadList(String key) {
    try {
      final raw = _prefs?.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('StorageService loadList error for key $key: $e');
    }
    return null;
  }

  // Generic List Saver
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final encoded = jsonEncode(list);
      await _prefs?.setString(key, encoded);
    } catch (e) {
      debugPrint('StorageService saveList error for key $key: $e');
    }
  }

  // Generic Bool Get/Set
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(key, value);
    } catch (e) {
      debugPrint('StorageService setBool error: $e');
    }
  }

  // First Launch & Splash Screen State
  bool hasSeenSplash() {
    return _prefs?.getBool(keyHasSeenSplash) ?? false;
  }

  Future<void> setSeenSplash(bool seen) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(keyHasSeenSplash, seen);
    } catch (e) {
      debugPrint('StorageService setSeenSplash error: $e');
    }
  }

  // Persistent User Authentication Session
  Map<String, String>? loadUserSession() {
    try {
      final raw = _prefs?.getString(keyUserSession);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      debugPrint('StorageService loadUserSession error: $e');
    }
    return null;
  }

  Future<void> saveUserSession(Map<String, String> session) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final encoded = jsonEncode(session);
      await _prefs?.setString(keyUserSession, encoded);
    } catch (e) {
      debugPrint('StorageService saveUserSession error: $e');
    }
  }

  Future<void> clearUserSession() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove(keyUserSession);
    } catch (e) {
      debugPrint('StorageService clearUserSession error: $e');
    }
  }

  // Custom Public Backend Server URL
  String? getCustomServerUrl() {
    return _prefs?.getString(keyCustomServerUrl);
  }

  Future<void> setCustomServerUrl(String? url) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (url == null || url.trim().isEmpty) {
        await _prefs?.remove(keyCustomServerUrl);
      } else {
        await _prefs?.setString(keyCustomServerUrl, url.trim());
      }
    } catch (e) {
      debugPrint('StorageService setCustomServerUrl error: $e');
    }
  }

  // Clear specific key or all
  Future<void> clearAll() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      debugPrint('StorageService clearAll error: $e');
    }
  }
}
