import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'estimate_repository.dart';
import 'project.dart';

/// Persists projects in SharedPreferences (browser localStorage on the web).
///
/// The first time it runs, the single summary saved by earlier versions
/// becomes a project called "My project", so nothing is lost.
class ProjectRepository {
  ProjectRepository(this._prefs);

  static const projectsKey = 'projects_v1';
  static const activeKey = 'active_project_v1';
  static const defaultName = 'My project';

  final SharedPreferences _prefs;

  List<Project> load() {
    final raw = _prefs.getString(projectsKey);
    if (raw == null) return _migrate();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final projects = <Project>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          projects.add(Project.fromJson(item));
        } on FormatException catch (e) {
          debugPrint('Skipping a saved project: $e');
        }
      }
      return projects;
    } on FormatException catch (e) {
      debugPrint('Ignoring unreadable saved projects: $e');
      return [];
    }
  }

  List<Project> _migrate() {
    final summary = EstimateRepository(_prefs).loadSummary();
    if (summary.isEmpty) return [];
    final project = Project.create(defaultName).copyWith(items: summary);
    save([project]);
    return [project];
  }

  Future<void> save(List<Project> projects) => _prefs.setString(
    projectsKey,
    jsonEncode([for (final p in projects) p.toJson()]),
  );

  String? loadActiveId() => _prefs.getString(activeKey);

  Future<void> saveActiveId(String id) => _prefs.setString(activeKey, id);
}
