// Filipino for the app's own text. Keys are the English text exactly as
// written in the screens; `{name}` placeholders are filled in at run time.
// Construction terms people say in English (slab, plywood, tiles, budget)
// stay in English, as builders and hardware stores use them.
const filipino = <String, String>{
  // Navigation
  'Estimate': 'Estimate',
  'History': 'Kasaysayan',
  'Project': 'Proyekto',
  'Settings': 'Settings',

  // Login
  'Sign in': 'Mag-sign in',
  'Estimate every material.\nPrice every job.':
      'Bilangin ang bawat materyales.\nPresyuhan ang bawat trabaho.',
  'Quantities and costs for Philippine construction, from a single wall to a contractor\'s bid.':
      'Dami at gastos para sa konstruksiyon sa Pilipinas, mula sa isang '
      'pader hanggang sa bid ng kontratista.',
  'Planning estimates. Confirm quantities and prices with your engineer and supplier before buying.':
      'Pang-plano lamang ang mga estimate. Kumpirmahin ang dami at presyo sa '
      'inyong engineer at supplier bago bumili.',
  '40 calculators, from earthworks and rebar to wiring and plumbing':
      '40 calculator, mula paghuhukay at bakal hanggang wiring at tubo',
  'Every material priced from a 2026 Philippine price book':
      'May presyo ang bawat materyales mula sa 2026 price book ng Pilipinas',
  'Projects with a bill of quantities, a budget, PDF and Google Sheets':
      'Mga proyektong may bill of quantities, budget, PDF at Google Sheets',
  'Welcome': 'Maligayang pagdating',
  'Sign in with Google to save your projects as spreadsheets in your own Google Drive.':
      'Mag-sign in sa Google para i-save ang mga proyekto bilang spreadsheet '
      'sa sarili ninyong Google Drive.',
  'or': 'o',
  'Continue without signing in': 'Magpatuloy nang hindi nagsa-sign in',
  'BuildQuantify can only open the spreadsheets it creates. Your projects stay in this browser, and you can sign in later from Settings.':
      'Ang mga spreadsheet lang na ginawa nito ang mabubuksan ng '
      'BuildQuantify. Nananatili sa browser na ito ang inyong mga proyekto, '
      'at puwede kayong mag-sign in mamaya sa Settings.',

  // Home
  'Categories': 'Mga kategorya',
  'Popular calculators': 'Mga madalas gamitin',
  'What are you building?': 'Ano ang itatayo ninyo?',
  'Estimate how much material to buy and what it costs, using sizes sold in the Philippines.':
      'Alamin kung gaano karaming materyales ang bibilhin at magkano, gamit '
      'ang mga sukat na mabibili sa Pilipinas.',
  'Open project': 'Buksan ang proyekto',
  'Search, e.g. paint or yero': 'Maghanap, hal. pintura o yero',
  'Clear search': 'Burahin ang hinahanap',
  'No matches': 'Walang tugma',
  'Nothing matches "{query}". Try a material such as blocks, paint, tiles, wire or pipe.':
      'Walang tumugma sa "{query}". Subukan ang hollow block, pintura, tiles, '
      'wire o tubo.',
  '1 material': '1 materyales',
  '{n} materials': '{n} materyales',
  '{n} calculators': '{n} calculator',
  '{category} materials': 'Materyales: {category}',
  'Recent': 'Kamakailan',
  'See all': 'Tingnan lahat',
  'Get started': 'Magsimula',
  'Pick a calculator and type your measurements':
      'Pumili ng calculator at ilagay ang mga sukat',
  'Add the result to a project': 'Idagdag ang resulta sa isang proyekto',
  'Download a PDF or save to Google Sheets':
      'Mag-download ng PDF o i-save sa Google Sheets',
  'Plan a house': 'Magplano ng bahay',
  'Not now': 'Mamaya na',
  'New here?': 'Bago rito?',
  'See how estimates work and how to send them to Google Sheets.':
      'Alamin kung paano gumagana ang estimate at paano ito ipadala sa '
      'Google Sheets.',

  // Calculator
  'Edit {material}': 'I-edit: {material}',
  'Definitions': 'Kahulugan',
  "How it's calculated": 'Paano kinuwenta',
  'Measurements': 'Mga sukat',
  'Options': 'Mga opsyon',
  'Price': 'Presyo',
  'Name in the project': 'Pangalan sa proyekto',
  'Name or mark (optional)': 'Pangalan o marka (opsyonal)',
  'F1, Kitchen wall, 2nd floor slab': 'F1, Pader ng kusina, slab ng 2nd floor',
  'Shown in the bill of quantities': 'Lalabas sa bill of quantities',
  'Editing an item in {project}': 'Ine-edit ang item sa {project}',
  'Change what you need, then choose Update item.':
      'Baguhin ang kailangan, saka piliin ang I-update ang item.',
  'Cancel': 'Kanselahin',
  '{value} is a lot for {field}. Check the unit.':
      'Masyadong malaki ang {value} para sa {field}. Suriin ang unit.',
  '{value} is a lot for {field}. Did you type {unit}?':
      'Masyadong malaki ang {value} para sa {field}. {unit} ba ang nailagay '
      'ninyo?',
  'Use {value}': 'Gamitin ang {value}',
  'Length unit': 'Unit ng haba',
  'Metres': 'Metro',
  'Feet': 'Talampakan',
  'More options': 'Iba pang opsyon',
  'not set': 'wala pa',
  'Choose one': 'Pumili ng isa',
  'What is {term}?': 'Ano ang {term}?',
  'Update': 'I-update',
  'Update item': 'I-update ang item',
  'Add as a new item': 'Idagdag bilang bagong item',
  'Change project': 'Palitan ang proyekto',
  'Your estimate': 'Ang inyong estimate',
  'Total cost': 'Kabuuang gastos',
  'Materials total': 'Kabuuan ng materyales',
  'at {price} per {unit}': 'sa {price} bawat {unit}',
  '{main} {unit} + {others} other materials':
      '{main} {unit} + {others} ibang materyales',
  'Materials only. Labour and markups are added in the project budget.':
      'Materyales lang ito. Idinadagdag ang labor at markup sa budget ng '
      'proyekto.',
  'Materials for this job': 'Materyales para sa trabahong ito',
  "How it's worked out": 'Paano kinuwenta',
  '{n} without a price yet. Tap a line to set one.':
      '{n} na wala pang presyo. I-tap ang linya para lagyan.',
  'Priced from your price book. Tap a line to change its price.':
      'Galing sa inyong price book ang presyo. I-tap ang linya para baguhin.',
  'no price yet': 'wala pang presyo',
  'Set price': 'Lagyan ng presyo',
  'Change price': 'Baguhin ang presyo',
  'Enter {fields} to see the estimate. It updates as you type.':
      'Ilagay ang {fields} para makita ang estimate. Nagbabago ito habang '
      'nagta-type kayo.',
  'your measurements': 'ang mga sukat',
  'and': 'at',
  'Add to {project}': 'Idagdag sa {project}',
  'Added to {project}': 'Naidagdag sa {project}',
  'Add': 'Idagdag',
  'Added': 'Naidagdag',
  'Check your measurements': 'Suriin ang mga sukat',
  'Saved to your price book for later estimates':
      'Mase-save sa price book para sa susunod na estimate',
  'View': 'Tingnan',
  'Save': 'I-save',

  // History
  'History cleared.': 'Nabura ang kasaysayan.',
  'Undo': 'Ibalik',
  'Your last 100 calculations, newest first':
      'Ang huling 100 kuwenta, pinakabago muna',
  'Clear history': 'Burahin ang kasaysayan',
  'No calculations yet': 'Wala pang kuwenta',
  'Every estimate you work out is kept here, so you can reopen and adjust it later.':
      'Dito itinatago ang bawat estimate, para mabuksan at maayos ninyo ito '
      'mamaya.',
  'Start an estimate': 'Magsimula ng estimate',
  'Inputs': 'Mga inilagay',
  'Open in calculator': 'Buksan sa calculator',
  'Delete': 'Burahin',
  'Page not found': 'Walang ganitong pahina',
  "That link doesn't lead anywhere in BuildQuantify.":
      'Walang patutunguhan ang link na iyan sa BuildQuantify.',
  'Go to home': 'Bumalik sa simula',

  // Project
  'Projects': 'Mga proyekto',
  'Keep each house, renovation or bid separate. Estimates go to the active project.':
      'Ihiwalay ang bawat bahay, renovation o bid. Napupunta ang estimate sa '
      'aktibong proyekto.',
  'Active': 'Aktibo',
  'New project': 'Bagong proyekto',
  'All projects': 'Lahat ng proyekto',
  'No estimates yet': 'Wala pang estimate',
  'Items': 'Mga item',
  'To buy': 'Bibilhin',
  'Budget': 'Budget',
  'New estimates go to another project.':
      'Sa ibang proyekto napupunta ang mga bagong estimate.',
  'Add estimates here': 'Dito idagdag ang estimate',
  'Add estimates to': 'Idagdag ang estimate sa',
  'Project actions': 'Mga aksiyon sa proyekto',
  'Edit details': 'I-edit ang detalye',
  'Duplicate': 'Doblehin',
  '{name} checklist': 'Checklist ng {name}',
  'Add a checklist': 'Magdagdag ng checklist',
  'Download PDF': 'I-download ang PDF',
  'Download for Excel (CSV)': 'I-download para sa Excel (CSV)',
  'Copy as text': 'Kopyahin bilang text',
  'Save to Google Sheets': 'I-save sa Google Sheets',
  'Update Google Sheet': 'I-update ang Google Sheet',
  'Open in Google Sheets': 'Buksan sa Google Sheets',
  'Remove all estimates': 'Alisin lahat ng estimate',
  'Delete project': 'Burahin ang proyekto',
  'Materials by trade': 'Materyales ayon sa trabaho',
  'Copied the shopping list.': 'Nakopya ang listahan ng bibilhin.',
  'Copied the project as text.': 'Nakopya ang proyekto bilang text.',
  'Every material merged across the estimates. Tap a line to change its price.':
      'Pinagsama ang bawat materyales mula sa lahat ng estimate. I-tap ang '
      'linya para baguhin ang presyo.',
  'Copy list': 'Kopyahin ang listahan',
  'Total contract price': 'Kabuuang presyo ng kontrata',
  'Project budget': 'Budget ng proyekto',
  '1 item': '1 item',
  '{n} items': '{n} item',
  'Preparing the PDF…': 'Inihahanda ang PDF…',
  'Add an estimate': 'Magdagdag ng estimate',
  'Search, e.g. footing, tiles, wire': 'Maghanap, hal. footing, tiles, wire',
  'Click a unit price to change it for this item only. Prices for the whole project are set under To buy.':
      'I-click ang unit price para baguhin ito sa item na ito lang. Sa '
      'Bibilhin binabago ang presyo para sa buong proyekto.',

  // Project items
  'Edit': 'I-edit',
  'Edit in calculator': 'I-edit sa calculator',
  'Name and note': 'Pangalan at tala',
  'Move up': 'Itaas',
  'Move down': 'Ibaba',
  'Remove': 'Alisin',
  'Name or mark': 'Pangalan o marka',
  'Note': 'Tala',
  'Where it is, what it includes, what to check':
      'Kung saan ito, ano ang kasama, ano ang susuriin',
  'Printed in the bill of quantities': 'Nakalimbag sa bill of quantities',

  // Checklist
  'Checklist': 'Checklist',
  'All {n} done': 'Tapos na lahat ng {n}',
  '{done} of {n} done · next: {item}':
      '{done} sa {n} ang tapos · susunod: {item}',
  'Checklist actions': 'Mga aksiyon sa checklist',
  'Remove checklist': 'Alisin ang checklist',
  'Show what is next': 'Ipakita ang susunod',
  'Show all {n}': 'Ipakita lahat ng {n}',
  '{item} not needed': 'Hindi kailangan ang {item}',
  'Needed': 'Kailangan',
  'Add more': 'Magdagdag pa',
  'Estimated': 'May estimate na',
  'Not needed': 'Hindi kailangan',
  'House': 'Bahay',
  'Renovation': 'Renovation',

  // Project details
  'Project name': 'Pangalan ng proyekto',
  'Client': 'Kliyente',
  'Optional': 'Opsyonal',
  'Location': 'Lokasyon',
  'Budget style': 'Uri ng budget',
  'Owner budget': 'Budget ng may-ari',
  'Contractor bid': 'Bid ng kontratista',

  // Budget
  'What these mean': 'Ano ang mga ito',
  'Owner': 'May-ari',
  'Contractor': 'Kontratista',
  'Labour': 'Labor',
  'Minor tools': 'Maliliit na gamit',
  'Hauling and delivery': 'Hakot at delivery',
  'Contingency': 'Contingency',
  'Overhead (OCM)': 'Overhead (OCM)',
  'Profit': 'Tubo',
  'Labour by trade': 'Labor ayon sa trabaho',
  'Leave empty to use {pct}%': 'Iwanang blangko para gamitin ang {pct}%',
  '{trade} labour': 'Labor sa {trade}',
  'Labour as a share of materials is a planning rule of thumb, about 30–45% for houses. Use your own quotes when you have them.':
      'Pang-plano lamang ang labor bilang bahagi ng materyales, mga 30–45% '
      'para sa bahay. Gamitin ang sariling quotation kapag mayroon na.',
  'Budget terms': 'Mga termino sa budget',
  'What the workers cost: masons, carpenters, steelmen, electricians, plumbers and helpers. Here it is a share of the materials, a planning rule of thumb; use your crew\'s quote when you have it.':
      'Bayad sa mga trabahador: mason, karpintero, panday-bakal, elektrisyan, '
      'tubero at helper. Dito, bahagi ito ng materyales bilang tantiya; '
      'gamitin ang quotation ng inyong grupo kapag mayroon na.',
  'Small tools and consumables used up on the job, such as trowels, saw blades and cutting discs, as a share of labour.':
      'Maliliit na gamit at nauubos sa trabaho, gaya ng kutsara, talim ng '
      'lagari at cutting disc, bilang bahagi ng labor.',
  'Trucking materials to the site and carting away debris.':
      'Paghakot ng materyales papunta sa site at pagtapon ng debris.',
  'Direct cost': 'Direktang gastos',
  'Materials, labour, tools and hauling together.':
      'Materyales, labor, gamit at hakot nang magkakasama.',
  'Money set aside for the unexpected: price increases, extra work and mistakes. 5–10% is usual for a house.':
      'Perang nakalaan sa hindi inaasahan: pagtaas ng presyo, dagdag na '
      'trabaho at pagkakamali. Karaniwan ang 5–10% para sa bahay.',
  'A contractor\'s overhead, contingencies and miscellaneous costs: office, permits, insurance, bonds, supervision and the like.':
      'Overhead, contingency at iba pang gastos ng kontratista: opisina, '
      'permit, insurance, bond, superbisyon at iba pa.',
  'What the contractor earns on the job.': 'Ang kinikita ng kontratista.',
  'Value-added tax. VAT-registered contractors charge 12% on their price; DPWH estimates use 5%.':
      'Value-added tax. 12% ang singil ng mga VAT-registered na kontratista; '
      '5% ang gamit sa estimate ng DPWH.',
  'The Department of Public Works and Highways. Its estimates follow Department Order 197 (2016), which sets overhead and profit by project size.':
      'Ang Department of Public Works and Highways. Sinusunod ng estimate '
      'nito ang Department Order 197 (2016), na nagtatakda ng overhead at '
      'tubo ayon sa laki ng proyekto.',

  // Settings
  'Prices, backups, Google Sheets and help':
      'Presyo, backup, Google Sheets at tulong',
  'Price book': 'Price book',
  'Your prices were cleared.': 'Nabura ang inyong mga presyo.',
  'Clear my prices': 'Burahin ang aking mga presyo',
  'Calculators fill in these prices and use them for the materials each job also needs. Set your supplier\'s price to use it everywhere.':
      'Ginagamit ng mga calculator ang mga presyong ito para sa materyales ng '
      'bawat trabaho. Ilagay ang presyo ng inyong supplier para magamit ito '
      'saanman.',
  'Where is the project?': 'Saan ang proyekto?',
  'Suggested prices are raised for regions where materials cost more':
      'Mas mataas ang mungkahing presyo sa mga rehiyong mas mahal ang '
      'materyales',
  'Search materials': 'Maghanap ng materyales',
  'Use the suggested price': 'Gamitin ang mungkahing presyo',
  'Open price book': 'Buksan ang price book',
  'Google Sheets': 'Google Sheets',
  'Sign in with Google to save projects as spreadsheets in your own Google Drive: the bill of quantities, the materials to buy and the budget, each on its own tab.':
      'Mag-sign in sa Google para i-save ang mga proyekto bilang spreadsheet '
      'sa sarili ninyong Google Drive: ang bill of quantities, ang bibilhin '
      'at ang budget, bawat isa sa sariling tab.',
  'Signed out of Google.': 'Naka-sign out na sa Google.',
  'Sign out': 'Mag-sign out',
  'Backup and restore': 'Backup at pagbabalik',
  'Your projects, prices and history are saved in this browser only. Download a backup to keep them safe or to move them to another device.':
      'Sa browser na ito lang naka-save ang inyong mga proyekto, presyo at '
      'kasaysayan. Mag-download ng backup para maingatan ito o mailipat sa '
      'ibang device.',
  'Download backup': 'I-download ang backup',
  'Restore from file': 'Ibalik mula sa file',
  'Restore this backup?': 'Ibalik ang backup na ito?',
  'Restore': 'Ibalik',
  'Google Drive': 'Google Drive',
  'Back up to Drive': 'I-back up sa Drive',
  'Restore from Drive': 'Ibalik mula sa Drive',
  'Back up automatically': 'Awtomatikong i-back up',
  'Saves changes to Drive within a minute, for an hour after each sign-in or backup':
      'Sine-save ang mga pagbabago sa Drive sa loob ng isang minuto, hanggang '
      'isang oras matapos ang bawat sign-in o backup',
  'Appearance and units': 'Hitsura at unit',
  'System': 'System',
  'Light': 'Maliwanag',
  'Dark': 'Madilim',
  'Language': 'Wika',
  'Help, definitions and documents stay in English, the language of plans and specifications.':
      'Nananatili sa English ang tulong, mga kahulugan at mga dokumento, ang '
      'wika ng mga plano at specification.',
  'Measure lengths in': 'Sukatin ang haba sa',
  'Calculators take lengths in feet when you choose feet. Results, documents and prices stay metric, as suppliers sell them.':
      'Talampakan ang tatanggapin ng mga calculator kapag pinili ito. '
      'Nananatiling metric ang resulta, dokumento at presyo, gaya ng benta '
      'ng mga supplier.',
  'Help and about': 'Tulong at tungkol sa app',

  // Crews and unit prices
  'By crew output': 'Ayon sa output ng grupo',
  '% of materials': '% ng materyales',
  "Crew-days for each work item from usual daily outputs, at the daily rates below. Each item's unit price analysis shows the crew.":
      'Ilang araw ng grupo sa bawat trabaho batay sa karaniwang output, sa '
      'arawang singil sa ibaba. Makikita ang grupo sa unit price analysis '
      'ng bawat item.',
  'A planning rule of thumb, about 30–45% of materials for houses. Use your own quotes when you have them.':
      'Tantiyang pang-plano, mga 30–45% ng materyales para sa bahay. Gamitin '
      'ang sariling quotation kapag mayroon na.',
  'Crew productivity': 'Bilis ng grupo',
  'Daily rates': 'Arawang singil',
  'Skilled {skilled}, helper {helper} a day':
      'Skilled {skilled}, helper {helper} bawat araw',
  'a day': 'bawat araw',
  'Foreman': 'Kapatas',
  'Skilled worker': 'Skilled na trabahador',
  'Helper': 'Helper',
  'One-bagger mixer': 'One-bagger mixer',
  'Concrete vibrator': 'Vibrator ng konkreto',
  'Plate compactor': 'Plate compactor',
  'Scaffolding set': 'Set ng scaffolding',
  'Welding machine': 'Makinang pang-weld',
  'Suggested rates are Metro Manila market rates for 2026, with meals and benefits. Enter what you pay.':
      'Ang mungkahing singil ay presyo sa Metro Manila sa 2026, kasama ang '
      'pagkain at benepisyo. Ilagay ang inyong ibinabayad.',
  'Use the suggested rates': 'Gamitin ang mungkahing singil',
  'General requirements': 'Pangkalahatang pangangailangan',
  'Mobilization, temporary facilities, permits…':
      'Mobilization, pansamantalang pasilidad, permit…',
  'Mobilization and demobilization': 'Mobilization at demobilization',
  'Temporary facilities: bodega, toilet, power and water':
      'Pansamantalang pasilidad: bodega, CR, kuryente at tubig',
  'Permits, clearances and fees': 'Permit, clearance at bayarin',
  'Occupational safety and health': 'Kaligtasan at kalusugan sa trabaho',
  'Project signboard': 'Signboard ng proyekto',
  'Clean-up and disposal of debris': 'Paglilinis at pagtapon ng debris',
  'Suggest amounts': 'Magmungkahi ng halaga',
  'Unit price analysis': 'Unit price analysis',
  'Each work item with its materials, crew and equipment. Tap one to see how its unit cost is built up.':
      'Bawat trabaho kasama ang materyales, grupo at kagamitan. I-tap para '
      'makita kung paano nabuo ang unit cost.',
  'Materials': 'Materyales',
  'days': 'araw',
  'Minor tools, {pct}% of labour': 'Maliliit na gamit, {pct}% ng labor',
  'Equipment rental': 'Upa sa kagamitan',
  'Direct cost per {unit}': 'Direktang gastos bawat {unit}',
  'Markups, {pct}%': 'Markup, {pct}%',
  'VAT, {pct}%': 'VAT, {pct}%',
  'Unit price per {unit}': 'Unit price bawat {unit}',

  // Quick budget, checks and contract
  'Quick budget by floor area': 'Mabilis na budget ayon sa lawak ng sahig',
  'A first idea of what a house costs, before measuring anything.':
      'Unang tantiya ng gastos ng bahay, bago pa sumukat.',
  'Quick budget': 'Mabilis na budget',
  'A first idea of what a house costs from its floor area, before anything is measured. Estimate the items to get a real figure.':
      'Unang tantiya ng gastos ng bahay batay sa lawak ng sahig, bago pa '
      'sumukat. I-estimate ang bawat item para sa totoong halaga.',
  'Floor area, all floors': 'Lawak ng sahig, lahat ng palapag',
  'Storeys': 'Palapag',
  'Finishes': 'Finishing',
  'About': 'Mga',
  "{low}–{high} a m², a contractor's price with VAT in Metro Manila":
      '{low}–{high} bawat m², presyo ng kontratista kasama ang VAT sa Metro '
      'Manila',
  'Ranges are typical for houses in late 2026 and vary with the site, the design and the region. Use them for a first conversation, never for a contract.':
      'Karaniwang saklaw ito para sa bahay sa huling bahagi ng 2026 at '
      'nag-iiba ayon sa lote, disenyo at rehiyon. Gamitin sa unang usapan, '
      'hindi sa kontrata.',
  'Estimate this house item by item': 'I-estimate ang bahay na ito bawat item',
  'Economy': 'Matipid',
  'Standard': 'Karaniwan',
  'Premium': 'Premium',
  'Plain finishes, local fixtures': 'Simpleng finishing, lokal na fixture',
  'Tiles throughout, mid-range fixtures':
      'Tiles sa buong bahay, katamtamang fixture',
  'Stone, engineered wood, imported fixtures':
      'Bato, engineered wood, imported na fixture',
  'Checks': 'Pagsusuri',
  'Nothing looks out of the ordinary.': 'Walang mukhang kakaiba.',
  '1 thing to look at before sending this out.':
      '1 bagay na dapat tingnan bago ito ipadala.',
  '{n} things to look at before sending this out.':
      '{n} bagay na dapat tingnan bago ito ipadala.',
  'Floor area': 'Lawak ng sahig',
  'Optional. All floors, for cost-per-m² checks':
      'Opsyonal. Lahat ng palapag, para sa pagsusuri ng gastos bawat m²',
  'Price escalation': 'Pagtaas ng presyo',
  'Contract': 'Kontrata',
  'Quotation': 'Quotation',
  'A quotation for the client: your business details, the scope by trade, the price, the payment terms and a schedule.':
      'Quotation para sa kliyente: detalye ng inyong negosyo, saklaw ng '
      'trabaho, presyo, paraan ng bayad at iskedyul.',
  'Valid for': 'Bisa nang',
  'Warranty': 'Warranty',
  'months': 'buwan',
  'Downpayment': 'Downpayment',
  'Retention': 'Retention',
  'Inclusions': 'Kasama',
  'One per line, e.g. Supply of materials and labour':
      'Isa bawat linya, hal. Materyales at labor',
  'Exclusions': 'Hindi kasama',
  'One per line, e.g. Building permit fees':
      'Isa bawat linya, hal. Bayad sa building permit',
  'Use common exclusions': 'Gamitin ang karaniwang hindi kasama',
  'Download quotation': 'I-download ang quotation',
  'Schedule': 'Iskedyul',
  "Worked out from each item's crew-days and the crews working at once, six working days a week. A planning guide, not a promise.":
      'Kinuwenta mula sa araw ng grupo ng bawat item at sa sabay-sabay na '
      'grupo, anim na araw bawat linggo. Gabay sa pagpaplano, hindi pangako.',
  'Add estimates to see a schedule.':
      'Magdagdag ng estimate para makita ang iskedyul.',
  'About {weeks} weeks ({days} working days)':
      'Mga {weeks} linggo ({days} araw ng trabaho)',
  'Set start date': 'Itakda ang petsa ng simula',
  'Starts {date}': 'Magsisimula {date}',
  'Finishes about {date}': 'Matatapos mga {date}',
  'Crews working at once': 'Sabay-sabay na grupo',
  'Schedule by phase': 'Iskedyul ayon sa yugto',
  'Planned progress (S-curve)': 'Planong pag-usad (S-curve)',
  'Week': 'Linggo',
  'Progress billing': 'Progress billing',
  "Bill the client for work done: each line's percent complete, less the downpayment recouped and the retention held.":
      'Singilin ang kliyente sa natapos na trabaho: porsiyento ng bawat '
      'linya, bawas ang naibalik na downpayment at retention.',
  'Contract price': 'Presyo ng kontrata',
  'Downpayment, {pct}%': 'Downpayment, {pct}%',
  'Billing {n}': 'Billing {n}',
  'Billing {n} · {date}': 'Billing {n} · {date}',
  '{pct}% complete · net due {amount}': '{pct}% tapos · babayaran {amount}',
  'Download billing {n}': 'I-download ang billing {n}',
  'Edit billing {n}': 'I-edit ang billing {n}',
  'New progress billing': 'Bagong progress billing',
  'Enter how far each line is done, in percent, to date. Lines start from the last billing.':
      'Ilagay kung ilang porsiyento na ang tapos sa bawat linya. Nagsisimula '
      'ang mga linya sa huling billing.',
  'All {pct}%': 'Lahat {pct}%',
  'Accomplished to date': 'Natapos hanggang ngayon',
  'This billing, before deductions': 'Billing na ito, bago ang bawas',
  'Variation orders': 'Variation order',
  'Work added or taken out after the contract was agreed. They change the contract price and can be billed.':
      'Trabahong idinagdag o inalis matapos ang kontrata. Binabago nito ang '
      'presyo ng kontrata at puwedeng singilin.',
  'Revised contract price': 'Binagong presyo ng kontrata',
  'Add a variation order': 'Magdagdag ng variation order',
  'Variation order': 'Variation order',
  'What changed': 'Ano ang nagbago',
  'Extra window in the kitchen': 'Dagdag na bintana sa kusina',
  'Taken out': 'Inalis',
  'Amount, with markups and VAT': 'Halaga, kasama ang markup at VAT',
  'Actual costs': 'Aktuwal na gastos',
  'Record what you spend to compare it with the budget as the work goes on.':
      'Itala ang ginagastos para maihambing sa budget habang tumatakbo ang '
      'trabaho.',
  'Spent': 'Nagastos',
  'Spent {spent} of a {direct} direct cost ({pct}%); the work is {done}% complete by the last billing.':
      'Nagastos ang {spent} sa {direct} na direktang gastos ({pct}%); {done}% '
      'na ang tapos ayon sa huling billing.',
  'Record an expense': 'Magtala ng gastos',
  'What for': 'Para saan',
  '50 bags of cement, week 2 payroll':
      '50 bag ng semento, sahod sa ika-2 linggo',
  'Amount': 'Halaga',
  'Subcontract': 'Subcontract',
  'Other': 'Iba pa',
  'Business profile': 'Profile ng negosyo',
  'Your business name and contact details, printed on quotations and progress billings.':
      'Pangalan at contact ng inyong negosyo, nakalimbag sa quotation at '
      'progress billing.',
  'Add your details': 'Ilagay ang inyong detalye',
  'Business or contractor name': 'Pangalan ng negosyo o kontratista',
  'Address': 'Address',
  'Phone': 'Telepono',
  'Email': 'Email',
  'TIN': 'TIN',
  'Prepared by (name and position)': 'Inihanda ni (pangalan at posisyon)',
};
