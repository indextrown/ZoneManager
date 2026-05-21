import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/room.dart';
import '../repositories/room_repository.dart';
import '../repositories/user_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required RoomRepository roomRepository,
    required UserRepository userRepository,
  }) : _roomRepository = roomRepository,
       _userRepository = userRepository;

  final RoomRepository _roomRepository;
  final UserRepository _userRepository;
  final Logger _log = Logger('HomeViewModel');

  StreamSubscription<List<Room>>? _roomsSubscription;

  List<Room> _rooms = [];
  bool _isLoadingRooms = true;
  bool _isInitializingUser = true;
  bool _isCreatingRoom = false;
  String? _userId;
  String? _errorMessage;

  List<Room> get rooms => _rooms;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isInitializingUser => _isInitializingUser;
  bool get isCreatingRoom => _isCreatingRoom;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _listenToRooms();
    await _loadUserId();
  }

  Future<void> refresh() async {
    _listenToRooms();
    await _loadUserId();
  }

  Future<void> _loadUserId() async {
    _isInitializingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userId = await _userRepository.getUserId();
      _log.info('사용자 ID 초기화: $_userId');
    } catch (e, stackTrace) {
      _errorMessage = '사용자 정보를 불러오지 못했습니다: $e';
      _log.severe('사용자 ID 초기화 실패', e, stackTrace);
    } finally {
      _isInitializingUser = false;
      notifyListeners();
    }
  }

  void _listenToRooms() {
    _roomsSubscription?.cancel();
    _isLoadingRooms = true;
    _errorMessage = null;

    _roomsSubscription = _roomRepository.watchRooms().listen(
      (rooms) {
        _rooms = rooms;
        _isLoadingRooms = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = '방 목록을 불러오지 못했습니다: $error';
        _isLoadingRooms = false;
        _log.severe('방 목록 구독 실패', error, stackTrace);
        notifyListeners();
      },
    );
  }

  Future<String> createRoom(String name) async {
    if (_userId == null) {
      throw StateError('사용자 ID 초기화 중입니다. 잠시 후 다시 시도해주세요.');
    }

    _isCreatingRoom = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final roomId = await _roomRepository.createRoom(name.trim(), _userId!);
      _log.info('방 생성 성공: $roomId');
      return roomId;
    } catch (e, stackTrace) {
      _errorMessage = '방 생성 중 오류가 발생했습니다: $e';
      _log.severe('방 생성 실패', e, stackTrace);
      rethrow;
    } finally {
      _isCreatingRoom = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    super.dispose();
  }
}
