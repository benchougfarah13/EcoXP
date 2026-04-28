import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists streaks, daily mission flags, and per-zone health boosts for GeoCampus.
class GeocampusLocalState {
  GeocampusLocalState._();

  static const _kLastPlayDate = 'geocampus_last_play_yyyy_mm_dd';
  static const _kStreak = 'geocampus_streak_days';
  static const _kDailyScan = 'geocampus_daily_scan_done';
  static const _kDailyMini = 'geocampus_daily_mini_done';
  static const _kZoneBoost = 'geocampus_zone_boost_';
  static const _kPreferredZone = 'geocampus_preferred_zone_id';

  static String _today() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());

  /// Call on hub open. Updates streak when the calendar day changes.
  static Future<int> rollStreakIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final last = prefs.getString(_kLastPlayDate);
    var streak = prefs.getInt(_kStreak) ?? 0;

    if (last == today) {
      return streak;
    }

    if (last == null || last.isEmpty) {
      streak = 1;
    } else {
      final lastDate = DateTime.tryParse(last);
      final now = DateTime.tryParse(today);
      if (lastDate != null && now != null) {
        final diff = now.difference(lastDate).inDays;
        if (diff == 1) {
          streak = streak + 1;
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    await prefs.setString(_kLastPlayDate, today);
    await prefs.setInt(_kStreak, streak);
    await prefs.setBool(_kDailyScan, false);
    await prefs.setBool(_kDailyMini, false);
    return streak;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStreak) ?? 0;
  }

  static Future<bool> isDailyScanDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyScan) ?? false;
  }

  static Future<void> markDailyScanDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyScan, true);
  }

  static Future<bool> isDailyMiniDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyMini) ?? false;
  }

  static Future<void> markDailyMiniDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyMini, true);
  }

  static Future<int> zoneBoost(String zoneId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_kZoneBoost$zoneId') ?? 0;
  }

  /// Adds [delta] to stored boost for a zone (clamped 0–40 cumulative boost).
  static Future<int> addZoneBoost(String zoneId, int delta) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('$_kZoneBoost$zoneId') ?? 0;
    final next = (current + delta).clamp(0, 40);
    await prefs.setInt('$_kZoneBoost$zoneId', next);
    return next;
  }

  /// Zone chosen on the session map (used as default on the campus hub).
  static Future<void> setPreferredZone(String zoneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredZone, zoneId);
  }

  static Future<String?> getPreferredZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPreferredZone);
  }
}
