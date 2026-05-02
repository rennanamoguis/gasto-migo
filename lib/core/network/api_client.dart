class ApiClient {
  static const String baseUrl =
      'https://seashell-antelope-329804.hostingersite.com/api';

  static Uri uri(String path) {
    return Uri.parse('$baseUrl$path');
  }
}
