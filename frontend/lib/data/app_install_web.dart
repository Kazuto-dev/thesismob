import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'app_install.dart';

AppInstaller createAppInstaller() => _BrowserInstaller();

/// Reads what index.html keeps in `window.bqInstall`: Chrome's offer to
/// install, which can arrive before the app has loaded, and whether the
/// app has been installed since.
class _BrowserInstaller implements AppInstaller {
  _BrowserInstaller() {
    web.window.addEventListener(
      'bq-install-changed',
      ((web.Event _) => _onChanged?.call()).toJS,
    );
  }

  void Function()? _onChanged;

  static final String _agent = web.window.navigator.userAgent;

  JSObject? get _state => web.window.getProperty<JSObject?>('bqInstall'.toJS);

  JSObject? get _offer => _state?.getProperty<JSObject?>('prompt'.toJS);

  @override
  late final InstallPlatform platform = () {
    if (RegExp('iPhone|iPad|iPod').hasMatch(_agent) ||
        // iPadOS presents itself as a Mac with a touch screen.
        (_agent.contains('Macintosh') &&
            web.window.navigator.maxTouchPoints > 1)) {
      return InstallPlatform.ios;
    }
    if (_agent.contains('Android')) return InstallPlatform.android;
    return InstallPlatform.other;
  }();

  @override
  bool get isInstalled =>
      web.window.matchMedia('(display-mode: standalone)').matches ||
      // Safari's own flag for apps opened from the home screen.
      web.window.navigator.getProperty<JSBoolean?>('standalone'.toJS)?.toDart ==
          true ||
      _state?.getProperty<JSBoolean?>('installed'.toJS)?.toDart == true;

  @override
  late final bool inAppBrowser = RegExp(
    r'FBAN|FBAV|FB_IAB|Instagram|Line/|TikTok|; wv\)',
  ).hasMatch(_agent);

  @override
  bool get canInstall => _offer != null;

  @override
  set onChanged(void Function()? callback) => _onChanged = callback;

  @override
  Future<bool> install() async {
    final offer = _offer;
    if (offer == null) return false;
    // Chrome's offer works once; a new one comes if the user declines.
    _state?.setProperty('prompt'.toJS, null);
    try {
      offer.callMethod<JSAny?>('prompt'.toJS);
      final choice = await offer
          .getProperty<JSPromise<JSObject>>('userChoice'.toJS)
          .toDart;
      return choice.getProperty<JSString?>('outcome'.toJS)?.toDart ==
          'accepted';
    } catch (_) {
      return false;
    } finally {
      _onChanged?.call();
    }
  }
}
