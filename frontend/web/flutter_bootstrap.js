{{flutter_js}}
{{flutter_build_config}}

// Starts the app without Flutter's own service worker. index.html
// registers sw.js for offline use; Flutter's worker would take its place,
// then remove itself and reload the page, so the app restarted a few
// seconds after opening and the install pop-up never got its turn.
_flutter.loader.load();
