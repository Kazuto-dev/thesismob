import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/estimate.dart';
import '../data/project.dart';
import '../data/project_repository.dart';

/// The user's projects and which one new estimates are added to.
///
/// There is always at least one project; deleting the last one leaves a
/// fresh, empty "My project".
class ProjectsController extends ChangeNotifier {
  ProjectsController(this._repository)
    : _projects = _repository.load(),
      _activeId = _repository.loadActiveId() {
    if (_projects.isEmpty) {
      _projects.add(Project.create(ProjectRepository.defaultName));
      _persist();
    }
    if (_activeId == null || _indexOf(_activeId!) < 0) {
      _activeId = _projects.first.id;
    }
  }

  final ProjectRepository _repository;
  final List<Project> _projects;
  String? _activeId;
  bool _disposed = false;

  /// False once the app has shut down and this controller was disposed.
  bool get isActive => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// All projects, most recently changed first.
  List<Project> get projects {
    final sorted = List<Project>.of(_projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  /// The project that "Add to project" adds to.
  Project get active => _projects[_indexOf(_activeId!)];

  Project? byId(String id) {
    final i = _indexOf(id);
    return i < 0 ? null : _projects[i];
  }

  int _indexOf(String id) => _projects.indexWhere((p) => p.id == id);

  void setActive(String id) {
    if (_activeId == id || _indexOf(id) < 0) return;
    _activeId = id;
    unawaited(_repository.saveActiveId(id));
    notifyListeners();
  }

  /// Creates a project and makes it the active one.
  Project create(
    String name, {
    String client = '',
    String location = '',
    CostSettings costs = CostSettings.owner,
  }) {
    final project = Project.create(
      name.trim().isEmpty ? ProjectRepository.defaultName : name.trim(),
    ).copyWith(client: client.trim(), location: location.trim(), costs: costs);
    _projects.add(project);
    _activeId = project.id;
    unawaited(_repository.saveActiveId(project.id));
    _persist();
    return project;
  }

  void updateDetails(
    String id, {
    String? name,
    String? client,
    String? location,
  }) => _update(
    id,
    (p) => p.copyWith(
      name: name == null || name.trim().isEmpty ? null : name.trim(),
      client: client?.trim(),
      location: location?.trim(),
    ),
  );

  void updateCosts(String id, CostSettings costs) =>
      _update(id, (p) => p.copyWith(costs: costs));

  /// Copies a project, items and settings included, as a new active one.
  Project duplicate(String id) {
    final source = byId(id)!;
    final now = DateTime.now();
    final copy = Project.create('${source.name} (copy)', now: now).copyWith(
      client: source.client,
      location: source.location,
      costs: source.costs,
      items: [for (final e in source.items) e.withId(Estimate.newId(now))],
    );
    _projects.add(copy);
    setActive(copy.id);
    _persist();
    return copy;
  }

  /// Removes a project and returns where it was, for undo.
  ({int index, Project project})? delete(String id) {
    final index = _indexOf(id);
    if (index < 0) return null;
    final removed = _projects.removeAt(index);
    if (_projects.isEmpty) {
      _projects.add(Project.create(ProjectRepository.defaultName));
    }
    if (_activeId == id) {
      _activeId = projects.first.id;
      unawaited(_repository.saveActiveId(_activeId!));
    }
    _persist();
    return (index: index, project: removed);
  }

  void restore(int index, Project project) {
    if (_indexOf(project.id) >= 0) return;
    _projects.insert(index.clamp(0, _projects.length), project);
    _persist();
  }

  // Items in a project. Without a project id, the active project is used.

  bool contains(String estimateId, {String? projectId}) =>
      (byId(projectId ?? _activeId!)?.items ?? const []).any(
        (e) => e.id == estimateId,
      );

  /// Whether any project holds the estimate [estimateId].
  bool isInAnyProject(String estimateId) =>
      _projects.any((p) => p.items.any((e) => e.id == estimateId));

  /// Adds [estimate] unless it is already there. Returns whether it was.
  bool add(Estimate estimate, {String? projectId}) {
    final id = projectId ?? _activeId!;
    if (contains(estimate.id, projectId: id)) return false;
    _update(id, (p) => p.copyWith(items: [...p.items, estimate]));
    return true;
  }

  ({int index, Estimate estimate})? removeItem(
    String estimateId, {
    String? projectId,
  }) {
    final id = projectId ?? _activeId!;
    final project = byId(id);
    if (project == null) return null;
    final index = project.items.indexWhere((e) => e.id == estimateId);
    if (index < 0) return null;
    final removed = project.items[index];
    _update(id, (p) => p.copyWith(items: [...p.items]..removeAt(index)));
    return (index: index, estimate: removed);
  }

  void restoreItem(int index, Estimate estimate, {String? projectId}) {
    final id = projectId ?? _activeId!;
    if (contains(estimate.id, projectId: id)) return;
    _update(id, (p) {
      final items = [...p.items];
      items.insert(index.clamp(0, items.length), estimate);
      return p.copyWith(items: items);
    });
  }

  /// Empties a project and returns what was removed, for undo.
  List<Estimate> clearItems({String? projectId}) {
    final id = projectId ?? _activeId!;
    final removed = byId(id)?.items ?? const <Estimate>[];
    _update(id, (p) => p.copyWith(items: const []));
    return removed;
  }

  void restoreItems(List<Estimate> items, {String? projectId}) =>
      _update(projectId ?? _activeId!, (p) => p.copyWith(items: items));

  /// Replaces an item, e.g. after its prices were edited.
  void updateItem(Estimate updated, {String? projectId}) => _update(
    projectId ?? _activeId!,
    (p) => p.copyWith(
      items: [for (final e in p.items) e.id == updated.id ? updated : e],
    ),
  );

  /// Remembers the Google spreadsheet a project was saved to.
  void setSheetId(String projectId, String sheetId) =>
      _update(projectId, (p) => p.copyWith(sheetId: sheetId));

  /// Applies [price] to every line of [itemKey] in a project, main
  /// materials and companions alike.
  void setPrice(String projectId, String itemKey, double price) => _update(
    projectId,
    (p) => p.copyWith(
      items: [
        for (final e in p.items)
          e.copyWith(
            unitPrice: mainKeyOf(e) == itemKey ? price : null,
            companions: [
              for (final l in e.companions)
                l.itemKey == itemKey ? l.withPrice(price) : l,
            ],
          ),
      ],
    ),
  );

  /// Everything, for a backup file.
  Map<String, dynamic> toJson() => {
    'projects': [for (final p in _projects) p.toJson()],
    'activeProjectId': _activeId,
  };

  /// Adds the projects in a backup, skipping ones that already exist.
  /// Returns how many were added.
  int import(List<Project> incoming) {
    var added = 0;
    for (final p in incoming) {
      if (_indexOf(p.id) >= 0) continue;
      _projects.add(p);
      added++;
    }
    if (added > 0) _persist();
    return added;
  }

  void _update(String id, Project Function(Project) change) {
    final index = _indexOf(id);
    if (index < 0) return;
    _projects[index] = change(_projects[index]);
    _persist();
  }

  void _persist() {
    unawaited(_repository.save(_projects));
    notifyListeners();
  }
}
