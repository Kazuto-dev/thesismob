import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/export/contract_pdf.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/state/profile_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('amounts are written in words', () {
    expect(pesosInWords(0), 'Zero Pesos and 00/100');
    expect(pesosInWords(1), 'One Pesos Only');
    expect(pesosInWords(21.5), 'Twenty-One Pesos and 50/100');
    expect(
      pesosInWords(1234567.08),
      'One Million Two Hundred Thirty-Four Thousand Five Hundred '
      'Sixty-Seven Pesos and 08/100',
    );
    expect(pesosInWords(2000000), 'Two Million Pesos Only');
  });

  test('a quotation and a billing are made as PDFs', testOn: 'vm', () async {
    final spec = materialById('chb')!;
    final e = Estimate.fromResult(
      materialId: 'chb',
      result: spec.calculate({
        'length': 10,
        'height': 3,
        'price': 25,
      }, spec.initialChoices),
      inputs: const {'length': 10, 'height': 3, 'price': 25},
      choices: spec.initialChoices,
    );
    var project = Project.create('Santos residence').copyWith(
      client: 'Maria Santos',
      costs: CostSettings.contractor,
      items: [e],
    );
    final keys = [for (final l in contractLines(project)) l.key];
    project = project.copyWith(
      contract: ContractData(
        terms: const QuoteTerms(exclusions: QuoteTerms.defaultExclusions),
        startDate: DateTime(2026, 11, 2),
        billings: [
          Billing(
            id: 'b1',
            date: DateTime(2026, 11, 30),
            progress: {for (final k in keys) k: 40},
          ),
        ],
      ),
    );
    const profile = BusinessProfile(
      name: 'Reyes Builders',
      preparedBy: 'Juan Reyes, Engineer',
    );
    final quote = await quotationPdf(
      project,
      profile,
      date: DateTime(2026, 10, 15),
    );
    expect(latin1.decode(quote.sublist(0, 5)), '%PDF-');
    final billing = await billingPdf(project, profile, 0);
    expect(latin1.decode(billing.sublist(0, 5)), '%PDF-');

    // A government client: the quotation notes and the billing shows the
    // taxes withheld.
    final government = project.copyWith(
      contract: project.contract.copyWith(
        terms: project.contract.terms.copyWith(client: ClientType.government),
      ),
    );
    expect(billingStatements(government).single.withholding, greaterThan(0));
    final govQuote = await quotationPdf(government, profile);
    expect(latin1.decode(govQuote.sublist(0, 5)), '%PDF-');
    final govBilling = await billingPdf(government, profile, 0);
    expect(latin1.decode(govBilling.sublist(0, 5)), '%PDF-');

    final flow = await cashFlowPdf(government, profile);
    expect(latin1.decode(flow.sublist(0, 5)), '%PDF-');
    final purchases = await purchaseSchedulePdf(government, profile);
    expect(latin1.decode(purchases.sublist(0, 5)), '%PDF-');
    final undated = await purchaseSchedulePdf(
      Project.create('Shed').copyWith(items: project.items),
      profile,
    );
    expect(latin1.decode(undated.sublist(0, 5)), '%PDF-');
  });
}
