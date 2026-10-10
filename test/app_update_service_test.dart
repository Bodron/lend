import 'package:flutter_test/flutter_test.dart';
import 'package:lend/services/app_update_service.dart';

void main() {
  test('compares release versions numerically', () {
    expect(compareAppVersions('1.9.0+28', '1.10.0'), lessThan(0));
    expect(compareAppVersions('1.10.0+28', '1.9.0'), greaterThan(0));
    expect(compareAppVersions('1.0.0+28', '1.0.0'), 0);
  });

  test('compares build numbers when configured', () {
    expect(compareAppVersions('1.0.0+28', '1.0.0+29'), lessThan(0));
    expect(compareAppVersions('1.0.0+29', '1.0.0+29'), 0);
  });

  test('ignores missing and malformed remote versions', () {
    expect(compareAppVersions('1.0.0+28', ''), isNull);
    expect(compareAppVersions('1.0.0+28', 'next'), isNull);
  });
}
