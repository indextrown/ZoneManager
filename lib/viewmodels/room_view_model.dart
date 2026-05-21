import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/room.dart';
import '../repositories/room_repository.dart';

class RoomViewModel extends ChangeNotifier {
  RoomViewModel({
    required RoomRepository roomRepository,
    required this.roomId,
    required this.userId,
  }) : _roomRepository = roomRepository;

  final RoomRepository _roomRepository;
  final Logger _log = Logger('RoomViewModel');

  final String roomId;
  final String userId;

  StreamSubscription<Room?>? _roomSubscription;

  Room? _room;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  Room? get room => _room;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isCreator => _room?.creatorId == userId;

  Future<void> initialize() async {
    _roomSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _roomSubscription = _roomRepository.watchRoom(roomId).listen(
      (room) {
        _room = room;
        _isLoading = false;
        if (room == null) {
          _errorMessage = '방을 찾을 수 없습니다.';
        } else {
          _errorMessage = null;
        }
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = '방 정보를 불러오지 못했습니다: $error';
        _isLoading = false;
        _log.severe('방 구독 실패', error, stackTrace);
        notifyListeners();
      },
    );
  }

  Future<void> addParkingZone({
    required String name,
    required int totalSpaces,
    required int colorValue,
  }) async {
    _setSubmitting(true);
    try {
      await _roomRepository.addParkingZone(
        roomId,
        ParkingZone(
          name: name.trim(),
          totalSpaces: totalSpaces,
          color: colorValue,
        ),
      );
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = '구역 추가 중 오류가 발생했습니다: $e';
      _log.severe('구역 추가 실패', e, stackTrace);
      rethrow;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> updateOccupiedSpaces(String zoneId, int delta) async {
    final currentRoom = _room;
    if (currentRoom == null) {
      return;
    }

    final zone = currentRoom.zones[zoneId];
    if (zone == null) {
      return;
    }

    final newCount = zone.occupiedSpaces + delta;
    if (newCount < 0 || newCount > zone.totalSpaces) {
      return;
    }

    try {
      await _roomRepository.updateOccupiedSpaces(roomId, zoneId, newCount);
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = '주차 공간 수 업데이트 중 오류가 발생했습니다: $e';
      _log.severe('주차 공간 수 업데이트 실패', e, stackTrace);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRoom() async {
    _setSubmitting(true);
    try {
      await _roomRepository.deleteRoom(roomId, userId);
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _log.severe('방 삭제 실패', e, stackTrace);
      rethrow;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> deleteParkingZone(String zoneId) async {
    _setSubmitting(true);
    try {
      await _roomRepository.deleteParkingZone(roomId, zoneId, userId);
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _log.severe('구역 삭제 실패', e, stackTrace);
      rethrow;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
