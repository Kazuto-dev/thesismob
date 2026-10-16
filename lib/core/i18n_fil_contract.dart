// Filipino for the schedule, cash flow, procurement and billing. Kept apart from i18n_fil.dart so each part of the
// app keeps its own table; see [filipinoTables].
const filipinoContract = <String, String>{
  // Schedule phases
  'Mobilization and layout': 'Mobilisasyon at layout',
  'Site preparation and earthworks': 'Paghahanda ng lote at paghuhukay',
  'Foundations': 'Pundasyon',
  'Columns and ground slab': 'Haligi at slab sa lupa',
  'Beams, upper slabs and stairs': 'Biga, slab sa itaas at hagdan',
  'Walls and rough-ins': 'Pader at rough-in',
  'Roof framing and roofing': 'Balangkas ng bubong at bubungan',
  'Plastering and waterproofing': 'Palitada at waterproofing',
  'Ceilings': 'Kisame',
  'Finishes and openings': 'Finishing, pinto at bintana',
  'Fixtures': 'Mga fixture',
  'Testing, punch list and turnover': 'Pagsusuri, punch list at turnover',

  // Schedule
  "Worked out from each item's crew-days, the crews working at once and how the phases overlap, six working days a week, with an allowance for rain and the regular holidays skipped. A planning guide, not a promise.":
      'Kinuwenta mula sa araw ng grupo ng bawat item, sa sabay-sabay na '
      'grupo at sa pagsasabay ng mga yugto, anim na araw bawat linggo, may '
      'palugit para sa ulan at walang trabaho sa regular holiday. Gabay sa '
      'pagpaplano, hindi pangako.',
  'About {weeks} weeks ({days} working days), about {months} months':
      'Mga {weeks} linggo ({days} araw ng trabaho), mga {months} buwan',
  'Includes {days} working days for rain and unworkable days.':
      'Kasama ang {days} araw ng trabaho para sa ulan at araw na hindi '
      'makapagtrabaho.',
  'Rain and unworkable days': 'Ulan at araw na walang trabaho',
  'Finish within': 'Tapusin sa loob ng',
  'weeks': 'linggo',
  'No target': 'Walang target',
  'Finish by a date': 'Tapusin bago ang petsa',
  'Finish by {date}': 'Tapusin bago ang {date}',
  'Clear the target': 'Alisin ang target',
  'Set a start date to use the finish-by date.':
      'Itakda ang petsa ng simula para magamit ang petsa ng pagtatapos.',
  'Meets the target of {weeks} weeks with the crews below.':
      'Aabot sa target na {weeks} linggo sa mga grupo sa ibaba.',
  "Can't finish within {weeks} weeks with a small site's limits; the fastest is about {fastest} weeks. Add crews by hand, or move the date.":
      'Hindi matatapos sa loob ng {weeks} linggo sa limitasyon ng maliit na '
      'site; ang pinakamabilis ay mga {fastest} linggo. Magdagdag ng grupo, '
      'o iurong ang petsa.',
  "Leave a trade on Auto and the app sizes its crews phase by phase, about three weeks of work each, within a small site's limits.":
      'Iwan sa Auto at ang app ang magtatakda ng grupo bawat yugto, mga '
      'tatlong linggong trabaho bawat isa, ayon sa limitasyon ng maliit na '
      'site.',
  'Other works': 'Iba pang trabaho',
  'Auto': 'Auto',
  'Auto · up to {n}': 'Auto · hanggang {n}',
  'Critical phases: {phases}': 'Kritikal na yugto: {phases}',
  '1 crew': '1 grupo',
  '{n} crews': '{n} grupo',
  'critical': 'kritikal',
};
