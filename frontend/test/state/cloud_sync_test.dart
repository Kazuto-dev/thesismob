import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/api_client.dart';
import 'package:thesismob/data/estimate_repository.dart';
import 'package:thesismob/data/project_repository.dart';
import 'package:thesismob/state/account_controller.dart';
import 'package:thesismob/state/cloud_sync.dart';
import 'package:thesismob/state/estimates_controller.dart';
import 'package:thesismob/state/price_book_controller.dart';
import 'package:thesismob/state/profile_controller.dart';
import 'package:thesismob/state/projects_controller.dart';

import '../fake_server.dart';
import 'projects_controller_test.dart' show estimate;

/// One device: the app's data on it and its sync with the account.
class Device {
  Device._(
    this.prefs,
    this.account,
    this.projects,
    this.prices,
    this.history,
    this.profile,
    this.sync,
  );

  static Future<Device> open(
    FakeServer server, [
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final api = ApiClient(baseUrl: 'https://api.test', client: server.client);
    final account = AccountController(prefs, api);
    final projects = ProjectsController(ProjectRepository(prefs));
    final prices = PriceBookController(prefs);
    final history = EstimatesController(EstimateRepository(prefs));
    final profile = ProfileController(prefs);
    final sync = CloudSync(
      prefs: prefs,
      api: api,
      account: account,
      projects: projects,
      prices: prices,
      history: history,
      profile: profile,
      delay: Duration.zero,
    );
    return Device._(prefs, account, projects, prices, history, profile, sync);
  }

  final SharedPreferences prefs;
  final AccountController account;
  final ProjectsController projects;
  final PriceBookController prices;
  final EstimatesController history;
  final ProfileController profile;
  final CloudSync sync;

  /// Everything saved on this device, to open it again later.
  Map<String, Object> get saved => {
    for (final k in prefs.getKeys()) k: prefs.get(k)!,
  };

  Future<void> signIn() async {
    await account.refresh();
    expect(await account.signInWithGoogle('google-token'), isNull);
    await sync.syncNow();
  }

  void close() => sync.dispose();
}

void main() {
  late FakeServer server;

  setUp(() => server = FakeServer());

  test('signed out, nothing is sent', () async {
    final d = await Device.open(server);
    d.projects.create('House');
    await d.sync.syncNow();
    expect(d.sync.state, SyncState.off);
    expect(server.projects, isEmpty);
    d.close();
  });

  test('the first sign-in moves what this browser holds to the account, '
      'and another device gets it all', () async {
    final a = await Device.open(server);
    final house = a.projects.create('House');
    a.projects.add(estimate(), projectId: house.id);
    a.prices.setPrice('chb_4', 30, supplier: 'Wilcon');
    a.history.record(estimate());
    a.profile.update(const BusinessProfile(name: 'Santos Builders'));
    await a.signIn();

    expect(a.sync.state, SyncState.saved);
    // The empty project every device starts with is not sent.
    expect(server.projects.keys, [house.id]);
    expect(server.documents.keys, containsAll(['price_book', 'history']));
    a.close();

    final b = await Device.open(server);
    await b.signIn();
    expect(b.projects.projects.map((p) => p.name), ['House']);
    expect(b.projects.projects.single.items, hasLength(1));
    expect(b.prices.priceOf('chb_4'), 30);
    expect(b.prices.quoteOf('chb_4')!.supplier, 'Wilcon');
    expect(b.history.history, hasLength(1));
    expect(b.profile.profile.name, 'Santos Builders');
    b.close();
  });

  test('changes go up on their own, and nothing is sent twice', () async {
    final a = await Device.open(server);
    final house = a.projects.create('House');
    await a.signIn();
    final calls = server.calls.length;

    // Syncing again with nothing changed only reads.
    await a.sync.syncNow();
    expect(
      server.calls.skip(calls).where((c) => !c.startsWith('GET')),
      isEmpty,
    );

    a.projects.updateDetails(house.id, name: 'Big house');
    await a.sync.flush();
    expect(server.projects[house.id]!['data']['name'], 'Big house');
    expect(server.projects[house.id]!['version'], 2);
    a.close();
  });

  test('a project deleted on one device goes from the others', () async {
    final a = await Device.open(server);
    final house = a.projects.create('House');
    a.projects.create('Shop');
    await a.signIn();
    final b = await Device.open(server);
    await b.signIn();
    expect(b.projects.projects, hasLength(2));

    b.projects.delete(house.id);
    await b.sync.flush();
    expect(server.projects.keys, isNot(contains(house.id)));

    await a.sync.syncNow();
    expect(a.projects.byId(house.id), isNull);
    a.close();
    b.close();
  });

  test('edits on two devices at once keep both', () async {
    final a = await Device.open(server);
    final house = a.projects.create('House');
    await a.signIn();
    final b = await Device.open(server);
    await b.signIn();

    a.projects.updateDetails(house.id, client: 'Maria');
    await a.sync.flush();
    b.projects.updateDetails(house.id, client: 'Jose');
    await b.sync.flush();

    expect(b.projects.byId(house.id)!.client, 'Maria');
    expect(
      b.projects.projects.map((p) => (p.name, p.client)),
      contains(('House (this device)', 'Jose')),
    );
    expect(server.projects, hasLength(2));
    a.close();
    b.close();
  });

  test('the free plan keeps two projects in the account and says how many '
      'are in this browser only', () async {
    final a = await Device.open(server);
    for (final name in ['One', 'Two', 'Three']) {
      a.projects.create(name);
    }
    await a.signIn();
    expect(server.projects, hasLength(2));
    expect(a.sync.state, SyncState.saved);
    expect(a.sync.deviceOnlyProjects, 1);
    a.close();
  });

  test('signing out keeps the account on the server; another account '
      'starts clean', () async {
    final a = await Device.open(server);
    a.projects.create('House');
    await a.signIn();
    await a.account.signOut();
    expect(server.projects, hasLength(1));
    expect(a.projects.projects.map((p) => p.name), contains('House'));
    final saved = a.saved;
    a.close();

    // The same browser, another person's account.
    final other = FakeServer();
    final b = await Device.open(other, {
      ...saved,
      CloudSync.key: (saved[CloudSync.key] as String).replaceFirst(
        '"owner":"u1"',
        '"owner":"someone-else"',
      ),
    });
    await b.signIn();
    expect(b.projects.projects.map((p) => p.name), [
      ProjectRepository.defaultName,
    ]);
    expect(other.projects, isEmpty);
    b.close();
  });

  test('offline, changes wait in this browser', () async {
    final a = await Device.open(server);
    await a.signIn();
    a.close();
    final offline = await Device.open(server, a.saved);
    // The server goes away.
    final api = ApiClient(
      baseUrl: 'https://api.test',
      client: MockClient((_) async => throw Exception('no connection')),
    );
    final sync = CloudSync(
      prefs: offline.prefs,
      api: api,
      account: offline.account,
      projects: offline.projects,
      prices: offline.prices,
      history: offline.history,
      profile: offline.profile,
      delay: Duration.zero,
    );
    offline.close();
    offline.projects.create('Garage');
    await sync.syncNow();
    expect(sync.state, SyncState.offline);
    expect(offline.projects.projects.map((p) => p.name), contains('Garage'));
    sync.dispose();
  });
}
