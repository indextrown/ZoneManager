import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import 'package:logging/logging.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _log = Logger('FirebaseService');

  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }

  Map<String, dynamic>? _extractRoomData(Object? value, String roomId) {
    final directRoomData = _asStringKeyedMap(value);
    if (directRoomData == null) {
      return null;
    }

    if (directRoomData.containsKey('creatorId') || directRoomData.containsKey('name')) {
      return directRoomData;
    }

    return _asStringKeyedMap(directRoomData[roomId]);
  }

  // 방 생성
  Future<String> createRoom(String name, String creatorId) async {
    try {
      _log.info('방 생성 시작 - name: $name, creatorId: $creatorId');
      final roomRef = _database.child('rooms').push();
      final room = Room(
        id: roomRef.key!,
        name: name,
        creatorId: creatorId,
        zones: {},
      );
      
      await roomRef.set(room.toJson());
      _log.info('방 생성 성공: ${room.id}, creatorId: ${room.creatorId}');
      return room.id;
    } catch (e, stackTrace) {
      _log.severe('방 생성 실패', e, stackTrace);
      rethrow;
    }
  }

  // 방 삭제
  Future<void> deleteRoom(String roomId, String userId) async {
    try {
      _log.info('방 삭제 시작 - roomId: $roomId, userId: $userId');
      
      final snapshot = await _database.child('rooms').child(roomId).get();
      _log.info('방 정보 조회 - exists: ${snapshot.exists}, value: ${snapshot.value}');
      
      if (!snapshot.exists) {
        throw '존재하지 않는 방입니다.';
      }

      final data = snapshot.value;
      _log.info('방 데이터 - type: ${data.runtimeType}, value: $data');
      
      final roomData = _extractRoomData(data, roomId);
      if (roomData == null) {
        throw '잘못된 방 데이터입니다.';
      }

      final creatorId = roomData['creatorId']?.toString();
      _log.info('방 creatorId 확인 - creatorId: $creatorId, userId: $userId');
      
      if (creatorId == null) {
        throw '방 생성자 정보를 찾을 수 없습니다.';
      }

      if (creatorId != userId) {
        throw '방 생성자만 삭제할 수 있습니다.';
      }

      await _database.child('rooms').child(roomId).remove();
      _log.info('방 삭제 성공: $roomId');
    } catch (e, stackTrace) {
      _log.severe('방 삭제 실패 - $e', e, stackTrace);
      rethrow;
    }
  }

  // 방 목록 가져오기
  Stream<List<Room>> getRooms() {
    return _database.child('rooms').onValue.map((event) {
      try {
        _log.info('방 목록 데이터 수신');
        final data = event.snapshot.value;
        if (data == null) {
          _log.info('방 목록이 비어있음');
          return [];
        }

        final roomsMap = _asStringKeyedMap(data);
        if (roomsMap == null) {
          _log.warning('데이터가 Map 형식이 아님');
          return [];
        }

        final rooms = roomsMap.entries.map((e) {
          final roomData = _asStringKeyedMap(e.value);
          if (roomData == null) {
            _log.warning('방 데이터가 Map 형식이 아님: ${e.key}');
            return null;
          }

          try {
            return Room.fromJson({
              ...roomData,
              'id': e.key,
            });
          } catch (e, stackTrace) {
            _log.warning('방 데이터 변환 실패', e, stackTrace);
            return null;
          }
        })
        .whereType<Room>()
        .toList();
        
        _log.info('방 목록 변환 성공: ${rooms.length}개의 방');
        return rooms;
      } catch (e, stackTrace) {
        _log.severe('방 목록 변환 실패', e, stackTrace);
        rethrow;
      }
    });
  }

  // 특정 방 정보 가져오기
  Stream<Room?> getRoom(String roomId) {
    return _database.child('rooms').child(roomId).onValue.map((event) {
      try {
        if (!event.snapshot.exists) {
          _log.info('방이 존재하지 않음: $roomId');
          return null;
        }
        final data = event.snapshot.value;
        final roomData = _extractRoomData(data, roomId);
        if (roomData == null) {
          _log.warning('방 데이터가 올바른 형식이 아님: $roomId');
          return null;
        }

        try {
          final room = Room.fromJson({
            ...roomData,
            'id': roomId,
          });
          _log.info('방 정보 변환 성공: $roomId');
          return room;
        } catch (e, stackTrace) {
          _log.severe('방 데이터 변환 실패: $roomId', e, stackTrace);
          return null;
        }
      } catch (e, stackTrace) {
        _log.severe('방 정보 변환 실패: $roomId', e, stackTrace);
        rethrow;
      }
    });
  }

  // 주차 구역 추가
  Future<void> addParkingZone(String roomId, ParkingZone zone) async {
    try {
      final zoneRef = _database.child('rooms').child(roomId).child('zones').push();
      await zoneRef.set(zone.toJson());
      _log.info('주차 구역 추가 성공: $roomId');
    } catch (e, stackTrace) {
      _log.severe('주차 구역 추가 실패', e, stackTrace);
      rethrow;
    }
  }

  // 주차 공간 수 업데이트
  Future<void> updateOccupiedSpaces(String roomId, String zoneId, int newCount) async {
    try {
      await _database
          .child('rooms')
          .child(roomId)
          .child('zones')
          .child(zoneId)
          .child('occupiedSpaces')
          .set(newCount);
      _log.info('주차 공간 수 업데이트 성공: $roomId, $zoneId, $newCount');
    } catch (e, stackTrace) {
      _log.severe('주차 공간 수 업데이트 실패', e, stackTrace);
      rethrow;
    }
  }

  // 주차 구역 삭제
  Future<void> deleteParkingZone(String roomId, String zoneId, String userId) async {
    try {
      _log.info('구역 삭제 시작 - roomId: $roomId, zoneId: $zoneId, userId: $userId');
      
      final snapshot = await _database.child('rooms').child(roomId).get();
      if (!snapshot.exists) {
        throw '존재하지 않는 방입니다.';
      }

      final data = snapshot.value;
      final roomData = _extractRoomData(data, roomId);
      if (roomData == null) {
        throw '잘못된 방 데이터입니다.';
      }

      final creatorId = roomData['creatorId']?.toString();
      _log.info('방 creatorId 확인 - creatorId: $creatorId, userId: $userId');
      
      if (creatorId == null) {
        throw '방 생성자 정보를 찾을 수 없습니다.';
      }

      if (creatorId != userId) {
        throw '방 생성자만 구역을 삭제할 수 있습니다.';
      }

      // 구역 삭제
      await _database
          .child('rooms')
          .child(roomId)
          .child('zones')
          .child(zoneId)
          .remove();
      _log.info('구역 삭제 성공 - roomId: $roomId, zoneId: $zoneId');
    } catch (e, stackTrace) {
      _log.severe('구역 삭제 실패 - $e', e, stackTrace);
      rethrow;
    }
  }
} 
