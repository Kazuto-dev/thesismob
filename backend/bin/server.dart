import 'dart:async';
import 'dart:io';

import 'package:buildquantify_server/buildquantify_server.dart';
import 'package:postgres/postgres.dart' show Pool;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Starts the API: reads the settings, brings the database up to date and
/// serves until stopped.
Future<void> main() async {
  final config = Config.fromEnvironment(Platform.environment);
  final pool = openPool(config.database);
  final applied = await _migrateWithRetry(pool);
  if (applied.isNotEmpty) stdout.writeln('Applied migrations $applied');

  final mailer = config.smtp == null
      ? LogMailer()
      : SmtpMailer(config.smtp!, config.mailFrom);
  final api = Api(
    store: Store(pool, config),
    google: HttpGoogleVerifier(),
    mailer: mailer,
  );
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(api.handler);
  final server = await io.serve(handler, InternetAddress.anyIPv4, config.port);
  server.autoCompress = true;
  stdout.writeln(
    'BuildQuantify API $apiVersion on port ${server.port}'
    '${config.googleClientIds.isEmpty ? ' (Google sign-in not set up)' : ''}'
    '${config.smtp == null ? ' (emails are only logged)' : ''}',
  );

  Future<void> stop(ProcessSignal signal) async {
    stdout.writeln('Stopping on $signal');
    await server.close();
    await pool.close();
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(stop);
  ProcessSignal.sigint.watch().listen(stop);
}

/// The database container may still be starting; try for a minute.
Future<List<int>> _migrateWithRetry(Pool<void> pool) async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await migrate(pool);
    } on Object catch (e) {
      if (attempt >= 30) rethrow;
      stderr.writeln('Database not ready ($e); retrying');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
}
