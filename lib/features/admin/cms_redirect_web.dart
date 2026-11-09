import 'dart:js_interop';

@JS('window.location.replace')
external void _replace(JSString destination);

/// Navigate without placing authentication tokens in URLs or sharing storage.
bool openCms(String destination) {
  final uri = Uri.tryParse(destination);
  if (uri == null ||
      uri.userInfo.isNotEmpty ||
      (uri.hasScheme && !['https', 'http'].contains(uri.scheme))) {
    return false;
  }
  _replace(destination.toJS);
  return true;
}
