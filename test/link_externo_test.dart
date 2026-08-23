import 'package:flutter_test/flutter_test.dart';
import 'package:ptk_plays/utils/LinkExterno.dart';

void main() {
  test('urlPoliticaPrivacidade aponta pro link certo da política de privacidade', () {
    expect(urlPoliticaPrivacidade, 'https://ptkplaysapp.blogspot.com/2025/12/ptk-plays-app-privacy-policy.html');
  });
}
