// Filipino for revisions, bid documents and quote comparison. Kept apart from i18n_fil.dart so each part of the
// app keeps its own table; see [filipinoTables].
const filipinoBids = <String, String>{
  // Project menu and downloads
  'Estimate revisions': 'Mga rebisyon ng estimate',
  'Bill of quantities for bidders': 'Bill of quantities para sa mga bidder',
  'Compare quotes': 'Ihambing ang mga quote',
  'Downloaded the bill for bidders.':
      'Na-download ang bill para sa mga bidder.',
  'Downloaded the bill for bidders (CSV).':
      'Na-download ang bill para sa mga bidder (CSV).',
  "Downloads aren't supported here.": 'Hindi puwedeng mag-download dito.',
  "Couldn't make the PDF.": 'Hindi nagawa ang PDF.',
  'The work items with their quantities, empty unit price and amount columns, a total to fill in and short instructions, for contractors or subcontractors to price.':
      'Ang mga gawain at dami nito, may blangkong hanay para sa unit price '
      'at halaga, kabuuang pupunan at maikling tagubilin, para presyuhan '
      'ng mga kontratista o subcontractor.',
  'Scope': 'Saklaw',
  'CSV': 'CSV',
  'PDF': 'PDF',
  'Whole job': 'Buong trabaho',
  'Structural works': 'Gawaing structural',
  'Architectural works': 'Gawaing architectural',
  'Electrical works': 'Gawaing electrical',
  'Plumbing works': 'Gawaing plumbing',
  'Other works': 'Iba pang gawain',

  // Revisions
  'Saved {rev}.': 'Na-save ang {rev}.',
  'Before restoring {rev}': 'Bago ibalik ang {rev}',
  'Restored {rev}.': 'Naibalik ang {rev}.',
  'Deleted {rev}.': 'Nabura ang {rev}.',
  'This project was deleted.': 'Nabura na ang proyektong ito.',
  'Go back to choose another project.':
      'Bumalik para pumili ng ibang proyekto.',
  'Not saved as a revision yet.': 'Hindi pa naka-save bilang rebisyon.',
  'The same as {rev}.': 'Kapareho ng {rev}.',
  'Changed since {rev}.': 'May binago mula sa {rev}.',
  'Save the estimate as a revision before you change it, such as when the client changes the plans. The last {max} revisions are kept with the project.':
      'I-save ang estimate bilang rebisyon bago ito baguhin, gaya ng kapag '
      'binago ng kliyente ang plano. Ang huling {max} rebisyon ay '
      'itinatabi kasama ng proyekto.',
  'Current estimate': 'Kasalukuyang estimate',
  'Save as a revision': 'I-save bilang rebisyon',
  'Saved revisions': 'Mga naka-save na rebisyon',
  'No revisions yet.': 'Wala pang rebisyon.',
  'Actions for {rev}': 'Mga aksiyon para sa {rev}',
  'Compare with the current estimate': 'Ihambing sa kasalukuyang estimate',
  'From': 'Mula sa',
  'To': 'Hanggang',
  'Compare': 'Ihambing',
  'Choose two different estimates.': 'Pumili ng dalawang magkaibang estimate.',
  '{rev} total': 'Kabuuan ng {rev}',
  'Change in total': 'Pagbabago sa kabuuan',
  'Change in direct cost': 'Pagbabago sa direktang gastos',
  'No differences.': 'Walang pagkakaiba.',
  'Items added': 'Mga idinagdag',
  'Items removed': 'Mga tinanggal',
  'Items changed': 'Mga binago',
  'Other changes in direct cost': 'Iba pang pagbabago sa direktang gastos',
  'Unchanged items, repriced by the settings':
      'Mga hindi binago, nagbago ang presyo dahil sa settings',
  'General requirements and hauling': 'Pangkalahatang pangangailangan at hakot',
  'Cost settings changed': 'Mga binagong cost settings',
  'Item amounts are direct costs: materials, labour, tools and equipment.':
      'Direktang gastos ang halaga ng bawat item: materyales, labor, gamit '
      'at kagamitan.',
  'Save {rev}': 'I-save ang {rev}',
  'Client removed the second bathroom':
      'Tinanggal ng kliyente ang ikalawang banyo',
  'Restore {rev}?': 'Ibalik ang {rev}?',
  "The project's items and cost settings are replaced with {rev}'s. Its details, contract, quotes and revisions stay.":
      'Papalitan ng sa {rev} ang mga item at cost settings ng proyekto. '
      'Mananatili ang detalye, kontrata, mga quote at mga rebisyon.',
  'Save the current estimate as a revision first':
      'I-save muna ang kasalukuyang estimate bilang rebisyon',
  'Labour, % of materials': 'Labor, % ng materyales',
  'Minor tools, % of labour': 'Maliliit na gamit, % ng labor',
  'VAT': 'VAT',

  // Quotes
  'Quotes from bidders': 'Mga quote ng bidder',
  'Deleted the quote from {bidder}.': 'Nabura ang quote ni {bidder}.',
  'Record the prices you get from contractors and subcontractors, and compare each with the estimate for the same scope.':
      'Itala ang mga presyong galing sa mga kontratista at subcontractor, at '
      'ihambing ang bawat isa sa estimate para sa parehong saklaw.',
  'With markups and VAT': 'May markup at VAT',
  'Compared with the estimate with its share of contingency, markups and VAT, as for contractors bidding to the owner.':
      'Inihambing sa estimate kasama ang bahagi nito sa contingency, markup '
      'at VAT, gaya ng bid ng kontratista sa may-ari.',
  'Compared with the direct cost of the work, as for subcontractors whose price becomes your cost.':
      'Inihambing sa direktang gastos ng trabaho, gaya ng subcontractor na '
      'ang presyo ay magiging gastos ninyo.',
  'Add a quote': 'Magdagdag ng quote',
  'No quotes yet': 'Wala pang quote',
  'Send the bill of quantities for bidders from the project menu, then add the prices that come back.':
      'Ipadala ang bill of quantities para sa mga bidder mula sa menu ng '
      'proyekto, saka idagdag ang mga presyong ibabalik nila.',
  'Actions for {bidder}': 'Mga aksiyon para kay {bidder}',
  'Take back the award': 'Bawiin ang award',
  'Mark as awarded': 'Markahang na-award',
  'More than {pct}% below the estimate: check that nothing in the scope was missed.':
      'Mahigit {pct}% na mas mababa sa estimate: tiyaking walang nakaligtaan '
      'sa saklaw.',
  'The price expired on {date}.': 'Nag-expire ang presyo noong {date}.',
  'Unnamed bidder': 'Bidder na walang pangalan',
  '{date} · valid until {until}': '{date} · valid hanggang {until}',
  'Awarded': 'Na-award',
  'Lowest': 'Pinakamababa',
  'Includes: {text}': 'Kasama: {text}',
  'Excludes: {text}': 'Hindi kasama: {text}',
  'Edit the quote': 'I-edit ang quote',
  'Bidder or subcontractor': 'Bidder o subcontractor',
  'Enter a name': 'Ilagay ang pangalan',
  'Estimate for this scope: {amount}': 'Estimate sa saklaw na ito: {amount}',
  'Quoted price': 'Presyong inalok',
  'Enter the price': 'Ilagay ang presyo',
  'Materials, labour, scaffolding': 'Materyales, labor, scaffolding',
  'Exclusions and notes': 'Hindi kasama at mga tala',
  'Permits, tiles supplied by the owner': 'Permit, tiles na galing sa may-ari',
  'Write down what each bidder leaves out, so quotes are compared on the same scope.':
      'Isulat ang hindi isinama ng bawat bidder, para maihambing ang mga '
      'quote sa parehong saklaw.',
};
