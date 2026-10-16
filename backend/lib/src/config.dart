/// The server's settings, read from environment variables so the same
/// build runs in tests, on a laptop and on the production server.
class Config {
  Config({
    this.port = 8080,
    required this.database,
    this.googleClientIds = const [],
    this.adminEmails = const {},
    this.allowedOrigins = const [],
    this.appUrl = '',
    this.smtp,
    this.mailFrom = '',
    this.salesEmail = '',
    this.trialDays = 14,
    this.freeProjects = 2,
    this.graceDays = 3,
    this.sessionDays = 30,
    this.codeValidDays = 30,
    this.businessPriceUsd = 20,
    this.businessPricePhp = 1150,
  });

  /// Reads the settings from [env], usually `Platform.environment`.
  factory Config.fromEnvironment(Map<String, String> env) {
    List<String> list(String key) => [
      for (final part in (env[key] ?? '').split(','))
        if (part.trim().isNotEmpty) part.trim(),
    ];
    int number(String key, int fallback) =>
        int.tryParse(env[key] ?? '') ?? fallback;
    final url = env['DATABASE_URL'];
    if (url == null || url.isEmpty) {
      throw StateError('DATABASE_URL is not set');
    }
    final smtpHost = env['SMTP_HOST'] ?? '';
    return Config(
      port: number('PORT', 8080),
      database: DatabaseSettings.parse(url),
      googleClientIds: list('GOOGLE_CLIENT_IDS'),
      adminEmails: {for (final e in list('ADMIN_EMAILS')) e.toLowerCase()},
      allowedOrigins: list('ALLOWED_ORIGINS'),
      appUrl: env['APP_URL'] ?? '',
      smtp: smtpHost.isEmpty
          ? null
          : SmtpSettings(
              host: smtpHost,
              port: number('SMTP_PORT', 587),
              username: env['SMTP_USERNAME'] ?? '',
              password: env['SMTP_PASSWORD'] ?? '',
            ),
      mailFrom: env['MAIL_FROM'] ?? env['SMTP_USERNAME'] ?? '',
      salesEmail: env['SALES_EMAIL'] ?? '',
      trialDays: number('TRIAL_DAYS', 14),
      freeProjects: number('FREE_PROJECTS', 2),
      graceDays: number('GRACE_DAYS', 3),
      sessionDays: number('SESSION_DAYS', 30),
      codeValidDays: number('CODE_VALID_DAYS', 30),
      businessPriceUsd: number('PRICE_BUSINESS_USD', 20),
      businessPricePhp: number('PRICE_BUSINESS_PHP', 1150),
    );
  }

  final int port;
  final DatabaseSettings database;

  /// OAuth client ids whose Google sign-ins are accepted. Sign-in is off
  /// until at least one is set.
  final List<String> googleClientIds;

  /// People who may issue codes and see every account, by email.
  final Set<String> adminEmails;

  /// Web origins allowed to call the API from a browser, such as
  /// `https://app.example.com`; `*` allows any (for development).
  final List<String> allowedOrigins;

  /// Where the app is, for links in emails.
  final String appUrl;

  /// The mail server; without one, emails are only logged.
  final SmtpSettings? smtp;
  final String mailFrom;

  /// Where Enterprise inquiries are sent.
  final String salesEmail;

  final int trialDays;

  /// Projects a free account may keep in the cloud.
  final int freeProjects;

  /// Days a lapsed plan keeps working, to allow for a late renewal.
  final int graceDays;
  final int sessionDays;

  /// Days a new code can be redeemed in.
  final int codeValidDays;

  final int businessPriceUsd;
  final int businessPricePhp;

  bool isAdmin(String email) => adminEmails.contains(email.toLowerCase());
}

class DatabaseSettings {
  const DatabaseSettings({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.ssl = false,
  });

  /// Parses `postgres://user:password@host:5432/database?sslmode=require`.
  factory DatabaseSettings.parse(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'postgres' && uri.scheme != 'postgresql') {
      throw FormatException('DATABASE_URL must start with postgres://', url);
    }
    final user = uri.userInfo.split(':');
    return DatabaseSettings(
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isEmpty ? 'postgres' : uri.pathSegments.first,
      username: Uri.decodeComponent(user.first),
      password: user.length > 1 ? Uri.decodeComponent(user[1]) : '',
      ssl: uri.queryParameters['sslmode'] == 'require',
    );
  }

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool ssl;
}

class SmtpSettings {
  const SmtpSettings({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String username;
  final String password;
}
