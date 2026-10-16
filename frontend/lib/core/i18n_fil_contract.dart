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

  // Withholding taxes
  'Client': 'Kliyente',
  'Individual or household': 'Indibidwal o pamilya',
  'Private company': 'Pribadong kumpanya',
  'Government': 'Gobyerno',
  'Client pays within': 'Magbabayad ang kliyente sa loob ng',
  'The client withholds {pct}% creditable income tax from each billing, before VAT, and gives you BIR Form 2307 to credit it.':
      'Ikakaltas ng kliyente ang {pct}% creditable income tax sa bawat '
      'billing, bago ang VAT, at bibigyan kayo ng BIR Form 2307 para '
      'maikredito ito.',
  'The client withholds {pct}% creditable income tax and {tax}% {name} from each billing, before VAT, and gives you BIR Form 2307 to credit them.':
      'Ikakaltas ng kliyente ang {pct}% creditable income tax at {tax}% '
      '{name} sa bawat billing, bago ang VAT, at bibigyan kayo ng BIR Form '
      '2307 para maikredito ang mga ito.',
  'VAT': 'VAT',
  'percentage tax': 'percentage tax',
  '{pct}% complete · net due {amount} · you receive {received} after {taxes} withheld':
      '{pct}% tapos · babayaran {amount} · matatanggap ninyo ang {received} '
      'matapos ikaltas ang {taxes}',

  // Cash flow
  'Cash flow': 'Daloy ng pera',
  'Money out and in month by month, before VAT: materials bought as each task starts, labour as the work is done and site costs every month, against the downpayment and the monthly billings, paid {days} days later less the downpayment recouped, the retention and the tax withheld.':
      'Labas at pasok ng pera bawat buwan, bago ang VAT: materyales na '
      'binibili sa simula ng bawat gawain, labor habang ginagawa at gastos '
      'sa site bawat buwan, laban sa downpayment at buwanang billing na '
      'binabayaran makalipas ang {days} araw, bawas ang naibalik na '
      'downpayment, retention at buwis na ikinaltas.',
  'Add estimates to see a cash flow.':
      'Magdagdag ng estimate para makita ang daloy ng pera.',
  'Peak cash need (working capital)':
      'Pinakamalaking kailangang pera (working capital)',
  'The downpayment and billings cover the costs all along.':
      'Sapat ang downpayment at billing sa gastos sa buong trabaho.',
  'Lowest in month {n}: have this much ready, or ask for a larger downpayment or faster payment.':
      'Pinakamababa sa buwan {n}: ihanda ang ganitong halaga, o humingi ng '
      'mas malaking downpayment o mas mabilis na bayad.',
  'Cash flow by month': 'Daloy ng pera bawat buwan',
  'Month': 'Buwan',
  'Month {n}': 'Buwan {n}',
  'Signing': 'Pirmahan',
  'Out': 'Labas',
  'In': 'Pasok',
  'Running total': 'Kabuuan',
  'Download cash flow': 'I-download ang daloy ng pera',
  'Downloaded the cash flow.': 'Na-download ang daloy ng pera.',

  // Purchase schedule
  'Purchase schedule': 'Iskedyul ng pagbili',
  'When each material is first needed, from the schedule, and when to order it given usual lead times: stock items 3–7 days, long-span roofing and tiles 7–14, plumbing fixtures up to 14, doors and windows made to measure 21–30. Ask your suppliers.':
      'Kailan unang kailangan ang bawat materyales, ayon sa iskedyul, at '
      'kailan ito oorderin ayon sa karaniwang tagal ng delivery: stock na '
      'gamit 3–7 araw, long-span na bubong at tiles 7–14, plumbing fixtures '
      'hanggang 14, pinto at bintanang ginagawa ayon sa sukat 21–30. '
      'Itanong sa inyong supplier.',
  'Add estimates to see when to buy.':
      'Magdagdag ng estimate para makita kung kailan bibili.',
  'Set a start date to see the dates.':
      'Itakda ang petsa ng simula para makita ang mga petsa.',
  'week {n}': 'linggo {n}',
  'Needed {week} for {phase} · order {days} days before':
      'Kailangan sa {week} para sa {phase} · umorder {days} araw bago nito',
  'Order by {order} · needed {needed} for {phase}':
      'Umorder bago ang {order} · kailangan sa {needed} para sa {phase}',
  'Show fewer': 'Ipakita ang mas kaunti',
  'Show all {n}': 'Ipakita ang lahat ng {n}',
  'Download purchase schedule': 'I-download ang iskedyul ng pagbili',
  'Downloaded the purchase schedule.': 'Na-download ang iskedyul ng pagbili.',

  // Learning from actuals
  'Learn from actuals': 'Matuto sa aktuwal',
  'The budget of the work done by the last billing, {pct}% complete, against what you recorded.':
      'Ang budget ng natapos na trabaho ayon sa huling billing, {pct}% '
      'tapos, laban sa inyong naitala.',
  '{earned} earned · {spent} spent': '{earned} kinita · {spent} nagastos',
  '{amount} under budget': '{amount} kulang sa budget',
  '{amount} over budget': '{amount} lampas sa budget',
  "Crews' productivity: {pct}% of the estimate's pace (earned labour ÷ labour spent).":
      'Bilis ng mga grupo: {pct}% ng bilis sa estimate (kinitang labor ÷ '
      'nagastos na labor).',
  'Early figures are rough: wait until about a fifth of the work is done.':
      'Magaspang pa ang maagang bilang: hintaying matapos ang mga '
      'ikalimang bahagi ng trabaho.',
  'Use {pct}% productivity for this estimate':
      'Gamitin ang {pct}% na bilis sa estimate na ito',
  'The estimate now uses {pct}% productivity.':
      'Gumagamit na ang estimate ng {pct}% na bilis.',
};
