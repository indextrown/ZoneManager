import 'package:logging/logging.dart';

class Room {
  static final _log = Logger('Room');
  final String id;
  final String name;
  final String creatorId;
  final Map<String, ParkingZone> zones;

  Room({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.zones,
  });

  Map<String, dynamic> toJson() {
    _log.info('Room toJson - id: $id, name: $name, creatorId: $creatorId');
    final json = {
      'name': name,
      'creatorId': creatorId,
      'zones': zones.map((key, value) => MapEntry(key, value.toJson())),
    };
    _log.info('Room toJson result: $json');
    return json;
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    Map<String, ParkingZone> zonesMap = {};
    if (json['zones'] != null) {
      final zones = json['zones'];
      if (zones is Map) {
        zones.forEach((key, value) {
          if (value is Map) {
            try {
              zonesMap[key.toString()] = ParkingZone.fromJson(
                Map<String, dynamic>.from(value)
              );
            } catch (e) {
              _log.warning('주차 구역 변환 실패: $key - $e');
            }
          }
        });
      }
    }

    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorId: json['creatorId'] as String,
      zones: zonesMap,
    );
  }
}

class ParkingZone {
  final String name;
  final int totalSpaces;
  final int occupiedSpaces;
  final int color;

  ParkingZone({
    required this.name,
    required this.totalSpaces,
    this.occupiedSpaces = 0,
    this.color = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'totalSpaces': totalSpaces,
    'occupiedSpaces': occupiedSpaces,
    'color': color,
  };

  factory ParkingZone.fromJson(Map<String, dynamic> json) => ParkingZone(
    name: json['name'] as String,
    totalSpaces: json['totalSpaces'] as int,
    occupiedSpaces: json['occupiedSpaces'] as int? ?? 0,
    color: json['color'] as int? ?? 0,
  );
} 