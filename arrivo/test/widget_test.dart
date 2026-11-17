import 'package:flutter_test/flutter_test.dart';

import 'package:arrivo/screens/home_screen.dart';

void main() {
  test('newer search requests replace older ones', () {
    expect(SearchRequestGuard.isLatest(requestToken: 1, latestRequestToken: 2),
        isFalse);
    expect(SearchRequestGuard.isLatest(requestToken: 2, latestRequestToken: 2),
        isTrue);
  });

  test('search tokens advance monotonically', () {
    expect(SearchRequestGuard.nextToken(0), 1);
    expect(SearchRequestGuard.nextToken(9), 10);
  });
}
