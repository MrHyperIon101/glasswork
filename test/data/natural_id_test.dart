import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/natural_id.dart';

void main() {
  test('the same key always gives the same id', () {
    expect(NaturalId.taskLabel('t', 'l'), NaturalId.taskLabel('t', 'l'));
  });

  test('different keys give different ids', () {
    final ids = {
      NaturalId.taskLabel('t', 'l'),
      NaturalId.taskLabel('l', 't'),
      NaturalId.fieldValue('t', 'l'),
      NaturalId.capacityProfile('t'),
      NaturalId.fallbackSchedule('t'),
    };
    expect(ids, hasLength(5));
  });

  test('ids are RFC 4122 version 5, matching an independent implementation', () {
    // Pinned against Python's uuid.uuid5 with the same namespace and names. Devices in use
    // hold rows under these ids, so a failure here means "don't change the derivation",
    // not "update the expected values".
    expect(
      NaturalId.taskLabel('task-1', 'label-1'),
      'b705da24-7db8-5697-959b-c993a650b57c',
    );
    expect(
      NaturalId.fieldValue('task-1', 'field-1'),
      '8010aa7e-8324-54ed-876f-8a81725f20c4',
    );
    expect(
      NaturalId.capacityProfile('ws-1'),
      '6b120e2d-ff98-5eee-8281-3778219020be',
    );
    expect(
      NaturalId.fallbackSchedule('ws-1'),
      '82839924-11b8-57e3-93b8-21ce36f27dae',
    );
  });
}
