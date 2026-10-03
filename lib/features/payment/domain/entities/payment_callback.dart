// Only the callback endpoint belonging to this Firebase project ends checkout.
bool isExpressPayCallback(String url, String projectId) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      uri.host == 'us-central1-$projectId.cloudfunctions.net' &&
      uri.path == '/expressPayCallback';
}
