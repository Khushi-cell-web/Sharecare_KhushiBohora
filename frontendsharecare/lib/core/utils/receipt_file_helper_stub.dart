/// Stub for web - receipt download not supported.
Future<void> saveAndOpenReceipt(List<int> bytes, String filename) async {
  // On web, could trigger download via dart:html - for now no-op
  throw UnsupportedError(
    'Receipt download not supported on web. Use a mobile or desktop app.',
  );
}
