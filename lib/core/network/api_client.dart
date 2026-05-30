class ApiClient {

  //for central API config, not yet used.
  static const String baseUrl =
      'https://gastomigo.rcamoguis.com/api';

  static Uri uri(String path) {
    return Uri.parse('$baseUrl$path');
  }
}
