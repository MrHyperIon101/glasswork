import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/sync/change_feed.dart';

void main() {
  test("a device's own push is not news to it, and another's is", () {
    expect(ChangeFeed.fromAnotherDevice({'client_id': 'me'}, const {}, 'me'), isFalse);
    expect(ChangeFeed.fromAnotherDevice({'client_id': 'phone'}, const {}, 'me'), isTrue);
    expect(
      ChangeFeed.fromAnotherDevice(const {}, {'client_id': 'phone'}, 'me'),
      isTrue,
      reason: 'a row gone, described by what it was',
    );
    expect(
      ChangeFeed.fromAnotherDevice({'id': 'x'}, const {}, 'me'),
      isTrue,
      reason: 'with no writer recorded, it is worth a pull',
    );
  });
}
