import 'package:flutter_test/flutter_test.dart';
import 'package:zonemanager/models/room.dart';

void main() {
  test('Room serializes and deserializes correctly', () {
    final room = Room(
      id: 'room-1',
      name: '테스트 방',
      creatorId: 'user-1',
      zones: {
        'zone-1': ParkingZone(
          name: 'A구역',
          totalSpaces: 10,
          occupiedSpaces: 3,
          color: 0xFFFFFFFF,
        ),
      },
    );

    final json = room.toJson();
    final restored = Room.fromJson({
      ...json,
      'id': room.id,
    });

    expect(restored.id, 'room-1');
    expect(restored.name, '테스트 방');
    expect(restored.creatorId, 'user-1');
    expect(restored.zones['zone-1']?.name, 'A구역');
    expect(restored.zones['zone-1']?.occupiedSpaces, 3);
  });
}
