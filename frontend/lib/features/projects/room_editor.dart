import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/rooms.dart';
import '../../materials/items_finishes.dart';

/// Opens the room editor for [room], or for a new room when it is null.
/// [levels] are the levels already in use, offered as shortcuts. Returns
/// the saved room, or null when the user cancels.
Future<Room?> editRoom(
  BuildContext context, {
  Room? room,
  List<String> levels = const [],
}) => Navigator.of(context).push(
  MaterialPageRoute<Room>(
    fullscreenDialog: true,
    builder: (_) => RoomEditor(room: room, levels: levels),
  ),
);

/// The form for one room: its name and level, size, doors and windows,
/// finishes and electrical points.
class RoomEditor extends StatefulWidget {
  const RoomEditor({super.key, this.room, this.levels = const []});

  final Room? room;
  final List<String> levels;

  @override
  State<RoomEditor> createState() => _RoomEditorState();
}

/// One door or window row in the form.
class _OpeningRow {
  _OpeningRow(RoomOpening o)
    : kind = o.kind,
      count = TextEditingController(text: '${o.count}'),
      width = TextEditingController(text: _show(o.width)),
      height = TextEditingController(text: _show(o.height)),
      sill = TextEditingController(text: _show(o.sill));

  final OpeningKind kind;
  final TextEditingController count;
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController sill;

  Iterable<TextEditingController> get controllers => [
    count,
    width,
    height,
    sill,
  ];

  RoomOpening get value => RoomOpening(
    kind: kind,
    width: _parse(width),
    height: _parse(height),
    sill: kind == OpeningKind.door ? 0 : _parse(sill),
    count: _parse(count).round(),
  );

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
  }
}

String _show(double? v) => switch (v) {
  null || <= 0 => '',
  final v when v == v.roundToDouble() => v.toInt().toString(),
  final v => formatNumber(v).replaceAll(',', ''),
};

double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

class _RoomEditorState extends State<RoomEditor> {
  late final Room _start =
      widget.room ??
      Room(
        id: Estimate.newId(DateTime.now()),
        name: '',
        level: widget.levels.isEmpty ? 'Ground floor' : widget.levels.last,
      );
  late final _name = TextEditingController(text: _start.name);
  late final _level = TextEditingController(text: _start.level);
  late bool _rectangle = _start.isRectangle || (_start.area ?? 0) <= 0;
  late final _length = TextEditingController(text: _show(_start.length));
  late final _width = TextEditingController(text: _show(_start.width));
  late final _area = TextEditingController(text: _show(_start.area));
  late final _perimeter = TextEditingController(text: _show(_start.perimeter));
  late final _height = TextEditingController(text: _show(_start.height));
  late final List<_OpeningRow> _openings = [
    for (final o in _start.openings) _OpeningRow(o),
  ];
  late FloorFinish _floor = _start.floor;
  late String _floorTile = _start.floorTile;
  late bool _skirting = _start.skirting;
  late WallFinish _wall = _start.wall;
  late String _wallTile = _start.wallTile;
  late final _tileHeight = TextEditingController(
    text: _show(_start.tileHeight),
  );
  late CeilingFinish _ceiling = _start.ceiling;
  late bool _paintCeiling = _start.paintCeiling;
  late final _lights = TextEditingController(
    text: _start.lights > 0 ? '${_start.lights}' : '',
  );
  late final _outlets = TextEditingController(
    text: _start.outlets > 0 ? '${_start.outlets}' : '',
  );

  /// Whether the user tried to save, so missing entries are flagged.
  bool _tried = false;

  List<TextEditingController> get _fields => [
    _name,
    _level,
    _length,
    _width,
    _area,
    _perimeter,
    _height,
    _tileHeight,
    _lights,
    _outlets,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in [..._fields, for (final o in _openings) ...o.controllers]) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    for (final o in _openings) {
      o.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {});

  void _addOpening(RoomOpening o) {
    final row = _OpeningRow(o);
    for (final c in row.controllers) {
      c.addListener(_changed);
    }
    setState(() => _openings.add(row));
  }

  void _removeOpening(_OpeningRow row) {
    setState(() => _openings.remove(row));
    // Dispose once the row's fields have left the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  /// The room as the form stands.
  Room get _room => Room(
    id: _start.id,
    name: _name.text.trim(),
    level: _level.text.trim(),
    length: _rectangle && _parse(_length) > 0 ? _parse(_length) : null,
    width: _rectangle && _parse(_width) > 0 ? _parse(_width) : null,
    area: !_rectangle && _parse(_area) > 0 ? _parse(_area) : null,
    perimeter: !_rectangle && _parse(_perimeter) > 0
        ? _parse(_perimeter)
        : null,
    height: _parse(_height),
    openings: [
      for (final o in _openings)
        if (o.value.count > 0 && o.value.width > 0 && o.value.height > 0)
          o.value,
    ],
    floor: _floor,
    floorTile: _floorTile,
    skirting: _skirting,
    wall: _wall,
    wallTile: _wallTile,
    tileHeight: _parse(_tileHeight) > 0
        ? _parse(_tileHeight)
        : Room.defaultTileHeight,
    ceiling: _ceiling,
    paintCeiling: _paintCeiling,
    lights: _parse(_lights).round(),
    outlets: _parse(_outlets).round(),
  );

  /// What is missing or wrong, by field, in English.
  Map<String, String> get _errors {
    final r = _room;
    return {
      if (r.name.isEmpty) 'name': 'Give the room a name',
      if (_rectangle && _parse(_length) <= 0) 'length': 'Enter the length',
      if (_rectangle && _parse(_width) <= 0) 'width': 'Enter the width',
      if (!_rectangle && _parse(_area) <= 0) 'area': 'Enter the floor area',
      if (r.height <= 0) 'height': 'Enter the ceiling height',
      if (r.floorArea > 0 &&
          r.height > 0 &&
          r.openingsBetween(0, r.height) >= r.wallLength * r.height)
        'openings': 'The doors and windows are larger than the walls',
    };
  }

  void _save() {
    if (_errors.isNotEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(_room);
  }

  String? _error(String key) {
    if (!_tried) return null;
    final e = _errors[key];
    return e == null ? null : context.tr(e);
  }

  Widget _number(
    TextEditingController c,
    String label, {
    String unit = 'm',
    String? helper,
    String? error,
    bool integer = false,
  }) => TextField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    inputFormatters: [DecimalInputFormatter(allowDecimal: !integer)],
    decoration: InputDecoration(
      labelText: context.tr(label),
      suffixText: unit,
      helperText: helper == null ? null : context.tr(helper),
      helperMaxLines: 3,
      errorText: error,
    ),
  );

  Widget _pair(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: Space.md),
      Expanded(child: b),
    ],
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
    child: Semantics(
      header: true,
      child: Text(
        context.tr(text),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) name,
    required ValueChanged<T> onChanged,
  }) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.tr(label)),
    items: [
      for (final v in values)
        DropdownMenuItem(
          value: v,
          child: Text(context.tr(name(v)), overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (v) {
      if (v != null) setState(() => onChanged(v));
    },
  );

  Widget _tileSize(String value, ValueChanged<String> onChanged) => _dropdown(
    label: 'Tile size',
    value: value,
    values: [for (final t in tileSizes) t.id],
    name: (id) => tileSizes.firstWhere((t) => t.id == id).label,
    onChanged: onChanged,
  );

  Widget _opening(_OpeningRow row) {
    final theme = Theme.of(context);
    final door = row.kind == OpeningKind.door;
    final name = context.tr(door ? 'Door' : 'Window');
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.xs,
          Space.xs,
          Space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  door ? Icons.door_front_door_outlined : Icons.window_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: context.tr('Remove {name}', {
                    'name': name.toLowerCase(),
                  }),
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeOpening(row),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _number(
                    row.count,
                    'How many',
                    unit: '',
                    integer: true,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(child: _number(row.width, 'Width')),
                const SizedBox(width: Space.sm),
                Expanded(child: _number(row.height, 'Height')),
                if (!door) ...[
                  const SizedBox(width: Space.sm),
                  Expanded(child: _number(row.sill, 'Sill')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = _room;
    final levels = {
      for (final l in [...widget.levels, 'Ground floor', 'Second floor'])
        if (l.trim().isNotEmpty) l.trim(),
    };
    final summary = [
      '${formatArea(_hundredths(room.floorArea))} ${context.tr('floor')}',
      '${formatArea(_hundredths(room.wallArea))} ${context.tr('walls')}',
      if (room.skirtingLength > 0)
        '${formatLength(_hundredths(room.skirtingLength))} '
            '${context.tr('skirting')}',
    ].join(' · ');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.room == null ? 'New room' : 'Edit room')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(
              onPressed: _save,
              child: Text(context.tr('Save')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xxxl),
        child: ContentWidth(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.room == null,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: context.tr('Room name'),
                  hintText: context.tr('Living room, Bedroom 1, T&B'),
                  errorText: _error('name'),
                ),
              ),
              const SizedBox(height: Space.sm),
              TextField(
                controller: _level,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: context.tr('Level'),
                  helperText: context.tr(
                    'Rooms on the same level share estimates',
                  ),
                ),
              ),
              Wrap(
                spacing: Space.sm,
                children: [
                  for (final l in levels)
                    ChoiceChip(
                      label: Text(l),
                      selected: _level.text.trim() == l,
                      showCheckmark: false,
                      onSelected: (_) => _level.text = l,
                    ),
                ],
              ),
              _heading('Size'),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(context.tr('Rectangle')),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(context.tr('Other shape')),
                  ),
                ],
                selected: {_rectangle},
                onSelectionChanged: (s) => setState(() => _rectangle = s.first),
              ),
              const SizedBox(height: Space.md),
              if (_rectangle)
                _pair(
                  _number(_length, 'Length', error: _error('length')),
                  _number(_width, 'Width', error: _error('width')),
                )
              else
                _pair(
                  _number(
                    _area,
                    'Floor area',
                    unit: 'm²',
                    error: _error('area'),
                  ),
                  _number(
                    _perimeter,
                    'Wall length',
                    helper: 'Round the room. Empty: taken as a square',
                  ),
                ),
              const SizedBox(height: Space.md),
              _number(
                _height,
                'Ceiling height',
                helper: 'Floor to ceiling',
                error: _error('height'),
              ),
              _heading('Doors and windows'),
              Text(
                context.tr(
                  'Left out of the wall finishes. Enter a door between two '
                  'rooms in both.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.sm),
              for (final o in _openings) _opening(o),
              if (_error('openings') case final e?)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(
                    e,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addOpening(const RoomOpening.door()),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add a door')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _addOpening(const RoomOpening.window()),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add a window')),
                  ),
                ],
              ),
              _heading('Floor'),
              _dropdown(
                label: 'Floor finish',
                value: _floor,
                values: FloorFinish.values,
                name: (f) => f.label,
                onChanged: (f) => _floor = f,
              ),
              if (_floor == FloorFinish.tiles) ...[
                const SizedBox(height: Space.md),
                _tileSize(_floorTile, (t) => _floorTile = t),
              ],
              if (_floor.takesSkirting)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Skirting')),
                  subtitle: Text(
                    context.tr(
                      _wall == WallFinish.tiles
                          ? 'Not needed below wall tiles'
                          : _floor == FloorFinish.tiles
                          ? '10 cm strips cut from the floor tiles'
                          : 'Trims round the walls',
                    ),
                  ),
                  value: _skirting && _wall != WallFinish.tiles,
                  onChanged: _wall == WallFinish.tiles
                      ? null
                      : (v) => setState(() => _skirting = v),
                ),
              _heading('Walls'),
              _dropdown(
                label: 'Wall finish',
                value: _wall,
                values: WallFinish.values,
                name: (w) => w.label,
                onChanged: (w) => _wall = w,
              ),
              if (_wall == WallFinish.tiles) ...[
                const SizedBox(height: Space.md),
                _pair(
                  _tileSize(_wallTile, (t) => _wallTile = t),
                  _number(
                    _tileHeight,
                    'Tile height',
                    helper: 'At the ceiling height or more: full height',
                  ),
                ),
              ],
              _heading('Ceiling'),
              _dropdown(
                label: 'Ceiling boards',
                value: _ceiling,
                values: CeilingFinish.values,
                name: (c) => c.label,
                onChanged: (c) => _ceiling = c,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('Paint the ceiling')),
                subtitle: Text(
                  context.tr(
                    _ceiling == CeilingFinish.none
                        ? 'The slab or roof underside'
                        : 'The boards',
                  ),
                ),
                value: _paintCeiling,
                onChanged: (v) => setState(() => _paintCeiling = v),
              ),
              _heading('Electrical'),
              _pair(
                _number(
                  _lights,
                  'Light points',
                  unit: 'pcs',
                  integer: true,
                  helper: 'Optional',
                ),
                _number(
                  _outlets,
                  'Outlets',
                  unit: 'pcs',
                  integer: true,
                  helper: 'Optional',
                ),
              ),
              const SizedBox(height: Space.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Text(
                    summary,
                    style: tabular(theme.textTheme.bodyMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [value] rounded to the centimetre or hundredth of a m².
double _hundredths(double value) => (value * 100).roundToDouble() / 100;
