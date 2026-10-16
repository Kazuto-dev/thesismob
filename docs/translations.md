# Translations

BuildQuantify can be shown in English or Filipino (Settings → Appearance
and units → Language). Calculations, the definitions and "How it's
calculated" behind each calculator, help, and the PDF, CSV and Google
Sheets documents stay in English, the language of plans and
specifications.

## How it works

Screens write their text in English and pass it through `context.tr`:

```dart
Text(context.tr('Add an estimate'))
Text(context.tr('Add to {project}', {'project': project.name}))
```

`tr` looks the English up in the user's language and falls back to the
English when there is no translation, so a missing entry never breaks a
screen. `{name}` placeholders are filled in after translating.

| File | Holds |
| --- | --- |
| [`lib/core/i18n.dart`](../frontend/lib/core/i18n.dart) | The languages, `tr` and `translate` |
| [`lib/core/i18n_fil.dart`](../frontend/lib/core/i18n_fil.dart) | Filipino for the screens |
| [`lib/core/i18n_fil_materials.dart`](../frontend/lib/core/i18n_fil_materials.dart) | Filipino for calculator names, fields and options |

Calculator labels are translated where they are shown, so the specs in
`lib/materials` stay in English.

## Adding or changing a translation

1. Copy the English exactly as the screen or calculator writes it,
   including punctuation and special characters (×, ², –, …), as the key.
2. Write the Filipino as builders, foremen and hardware stores say it.
   Keep the construction terms people use in English (slab, plywood,
   tiles, PVC, THHN), every number and unit, and every `{placeholder}`.
3. Keep it about as long as the English; many labels sit on buttons.
4. Run `flutter test test/core/i18n_test.dart`. It fails when a
   placeholder is lost or a calculator key no longer matches its English.

The translations were written for this release and should be reviewed by
a native speaker who works in construction before wide use.
