import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './my_app_routes.dart' show MyRouteGroup, kAboutRoute, kAllRoutes;
import './my_route.dart';
import 'constants.dart';

final mySettingsProvider =
    ChangeNotifierProvider<MyAppSettings>((ref) => throw UnimplementedError());

class MyAppSettings extends ChangeNotifier {
  static final _kRoutenameToRouteMap = {
    for (MyRoute route in kAllRoutes) route.routeName: route
  };

  static Future<MyAppSettings> create() async {
    if (!kIsWeb) {
      debugPrint('app dir=${await getApplicationDocumentsDirectory()}');
    }
    final sharedPref = await SharedPreferences.getInstance();
    final s = MyAppSettings._(sharedPref);
    await s._init();
    return s;
  }

  final SharedPreferences _pref;

  MyAppSettings._(this._pref);

  Future<void> _init() async {
    // When first time opening the app: mark all routes as known -- we only
    // display a red dot for *new* routes.
    final knownRoutes = _pref.getStringList(kKnownRoutesKey);
    debugPrint('knownroute=$knownRoutes');
    // Check if user opens the app for the FIRST time.
    if (knownRoutes == null || knownRoutes.length < 50) {
      debugPrint('Adding all routes to known routes...');
      final allrouteNames = _kRoutenameToRouteMap.keys.toList()
        ..add(kAboutRoute.routeName);
      await _pref.setStringList(kKnownRoutesKey, allrouteNames);
      debugPrint('knownroute=${_pref.getStringList(kKnownRoutesKey)}');
    }
  }

  static const _kDarkModePreferenceKey = 'DARK_MODE';
  bool get isDarkMode => _pref.getBool(_kDarkModePreferenceKey) ?? false;

  // ignore:avoid_positional_boolean_parameters
  void setDarkMode(bool val) {
    _pref.setBool(_kDarkModePreferenceKey, val);
    notifyListeners();
  }

  /// The list of route names in search history.
  static const _kSearchHistoryPreferenceKey = 'SEARCH_HISTORY';
  List<String> get searchHistory =>
      _pref.getStringList(_kSearchHistoryPreferenceKey) ?? [];

  void addSearchHistory(String routeName) {
    List<String> history = this.searchHistory;
    history.remove(routeName);
    history.insert(0, routeName);
    if (history.length >= 10) {
      history = history.take(10).toList();
    }
    _pref.setStringList(_kSearchHistoryPreferenceKey, history);
  }

  // Bookmarks
  static const _kBookmarkedRoutesPreferenceKey = 'BOOKMARKED_ROUTES';
  List<String> get starredRoutenames =>
      _pref.getStringList(_kBookmarkedRoutesPreferenceKey) ?? [];

  List<MyRoute> get starredRoutes => [
        for (final String routename in this.starredRoutenames)
          if (_kRoutenameToRouteMap[routename] != null)
            _kRoutenameToRouteMap[routename]!
      ];

  // Returns a widget showing the star status of one demo route.
  Widget starStatusOfRoute(String routeName) {
    return IconButton(
      tooltip: 'Bookmark',
      icon: Icon(
        this.isStarred(routeName) ? Icons.star : Icons.star_border,
        color: this.isStarred(routeName) ? Colors.yellow : Colors.grey,
      ),
      onPressed: () {
        this.toggleStarred(routeName);
        kAnalytics?.logEvent(
          name:
              'evt_${this.isStarred(routeName) ? 'starRoute' : 'unstarRoute'}',
          parameters: {'routeName': routeName},
        );
      },
    );
  }

  bool isStarred(String routeName) => starredRoutenames.contains(routeName);

  void toggleStarred(String routeName) {
    final staredRoutes = this.starredRoutenames;
    if (isStarred(routeName)) {
      staredRoutes.remove(routeName);
    } else {
      staredRoutes.add(routeName);
    }
    final dedupedStaredRoutes = Set<String>.from(staredRoutes).toList();
    _pref.setStringList(_kBookmarkedRoutesPreferenceKey, dedupedStaredRoutes);
    notifyListeners();
  }

  // Used to decide if an example is newly added. We will show a red dot for
  // newly added routes.
  static const kKnownRoutesKey = 'KNOWN_ROUTE_NAMES';
  bool isNewRoute(MyRoute route) =>
      !(_pref.getStringList(kKnownRoutesKey)?.contains(route.routeName) ??
          false);

  void markRouteKnown(MyRoute route) {
    if (isNewRoute(route)) {
      final knowRoutes = _pref.getStringList(kKnownRoutesKey)
        ?..add(route.routeName);
      _pref.setStringList(kKnownRoutesKey, knowRoutes ?? []);
      notifyListeners();
    }
  }

  // Returns the number of new example routes in this group.
  int numNewRoutes(MyRouteGroup group) {
    return group.routes.where(isNewRoute).length;
  }

  // Number of coins rewarded.
  static const _kCoinsKey = 'NUM_COINS';
  int get rewardCoins => _pref.getInt(_kCoinsKey) ?? 0;
  set rewardCoins(int c) {
    _pref.setInt(_kCoinsKey, c);
    notifyListeners();
  }

  // Number of chatGPT conversion turns allowed.
  static const _kChatGptTurnsKey = 'CHATGPT_TURNS_ALLOWED';
  int get chatGptTurns => _pref.getInt(_kChatGptTurnsKey) ?? 10;
  set chatGptTurns(int c) {
    _pref.setInt(_kChatGptTurnsKey, c);
    notifyListeners();
  }

  // Whether the intro screen is shown.
  static const _kIntroShownKey = 'INTRO_IS_SHOWN';
  bool get introIsShown => _pref.getBool(_kIntroShownKey) ?? kIsWeb;
  set introIsShown(bool val) => _pref.setBool(_kIntroShownKey, val);

  // Which tab the user was in the last time
  static const _kCurrentTabIdxKey = 'CURRENT_TAB_INDEX';
  int get currentTabIdx => _pref.getInt(_kCurrentTabIdxKey) ?? 0;
  set currentTabIdx(int n) {
    _pref.setInt(_kCurrentTabIdxKey, n);
    notifyListeners();
  }
}

/// Extend the sharedPreference to support maps.
/// TODO: examine the logic.
/// TODO: can we use StateProvider to watch changes? cf. https://riverpod.dev/docs/concepts/scopes#initialization-of-synchronous-provider-for-async-apis
extension SharedPreferencesMapExtension on SharedPreferences {
  /// Set a map in SharedPreferences
  Future<void> setMap(String key, Map<String, dynamic> map) async {
    final jsonString = jsonEncode(map);
    await setString(key, jsonString);
  }

  /// Get a map from SharedPreferences
  Map<String, dynamic>? getMap(String key) {
    final jsonString = getString(key) ?? '{}';
    try {
      final obj = jsonDecode(jsonString);
      if (obj is Map<String, dynamic>) return obj;
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add or update an entry in a map in SharedPreferences
  Future<void> updateMapEntry(String key, String mapKey, dynamic value) async {
    final map = getMap(key);
    if (map != null) {
      map[mapKey] = value;
      await setMap(key, map);
    }
  }

  /// Remove an entry from a map in SharedPreferences
  Future<void> removeMapEntry(String key, String mapKey) async {
    final map = getMap(key);
    if (map != null) {
      map.remove(mapKey);
      await setMap(key, map);
    }
  }

  /// Insert a set of key-value pairs into a map in SharedPreferences
  Future<void> insertMapEntries(
      String key, Map<String, dynamic> entries) async {
    final map = getMap(key);
    if (map != null) {
      map.addAll(entries);
      await setMap(key, map);
    }
  }

  /// Remove a set of key-value pairs from a map in SharedPreferences
  Future<void> removeMapEntries(String key, Iterable<String> keys) async {
    final map = getMap(key);
    if (map != null) {
      for (final key in keys) {
        map.remove(key);
      }
      await setMap(key, map);
    }
  }

  /// Check if a key exists in a map in SharedPreferences
  bool containsMapEntry(String key, String mapKey) {
    final map = getMap(key);
    return map != null && map.containsKey(mapKey);
  }

  /// Clear a map in SharedPreferences
  Future<void> clearMap(String key) async {
    await setString(key, '{}');
  }
}
