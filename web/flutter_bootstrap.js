{{flutter_js}}
{{flutter_build_config}}

// No service worker. Flutter's (deprecated) worker cached main.dart.js and
// kept serving the previous build after every deploy. Freshness comes from
// versioned URLs instead (tools/ci/assemble-site.sh), and a self-removing
// flutter_service_worker.js clears the old worker for returning visitors.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations()
    .then(function (regs) { regs.forEach(function (r) { r.unregister(); }); })
    .catch(function () {});
}

_flutter.loader.load();
