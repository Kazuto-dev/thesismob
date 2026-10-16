import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

import 'config.dart';

/// An email to send.
typedef Email = ({String to, String subject, String text, String? replyTo});

/// Sends email, or pretends to.
abstract interface class Mailer {
  Future<void> send(Email email);
}

/// Sends through an SMTP server, such as Gmail or Google Workspace with an
/// app password (smtp.gmail.com, port 587).
class SmtpMailer implements Mailer {
  SmtpMailer(SmtpSettings settings, this.from)
    : _server = SmtpServer(
        settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
        // Port 465 is TLS from the start; 587 upgrades with STARTTLS.
        ssl: settings.port == 465,
      );

  final SmtpServer _server;
  final String from;

  @override
  Future<void> send(Email email) async {
    final message = mailer.Message()
      ..from = _address(from)
      ..recipients.add(email.to)
      ..subject = email.subject
      ..text = email.text;
    if (email.replyTo != null) message.headers['Reply-To'] = email.replyTo!;
    await mailer.send(message, _server, timeout: const Duration(seconds: 30));
  }

  /// `Name <address>` or a bare address.
  static mailer.Address _address(String from) {
    final match = RegExp(r'^\s*(.*?)\s*<(.+)>\s*$').firstMatch(from);
    return match == null
        ? mailer.Address(from.trim())
        : mailer.Address(match[2]!, match[1]!.isEmpty ? null : match[1]);
  }
}

/// Writes emails to the log instead, for development and tests.
class LogMailer implements Mailer {
  final sent = <Email>[];

  @override
  Future<void> send(Email email) async {
    sent.add(email);
    stdout.writeln('[mail] to ${email.to}: ${email.subject}');
  }
}

/// Sends [email] without failing the request when the mail server is
/// down; the failure is logged and the caller is told.
Future<bool> trySend(Mailer mailer, Email email) async {
  try {
    await mailer.send(email);
    return true;
  } on Object catch (e) {
    stderr.writeln('[mail] could not send "${email.subject}": $e');
    return false;
  }
}
