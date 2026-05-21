import '../models/room.dart';
import '../services/firebase_service.dart';
import 'room_repository.dart';

class FirebaseRoomRepository implements RoomRepository {
  FirebaseRoomRepository({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  @override
  Stream<List<Room>> watchRooms() => _firebaseService.getRooms();

  @override
  Stream<Room?> watchRoom(String roomId) => _firebaseService.getRoom(roomId);

  @override
  Future<String> createRoom(String name, String creatorId) {
    return _firebaseService.createRoom(name, creatorId);
  }

  @override
  Future<void> deleteRoom(String roomId, String userId) {
    return _firebaseService.deleteRoom(roomId, userId);
  }

  @override
  Future<void> addParkingZone(String roomId, ParkingZone zone) {
    return _firebaseService.addParkingZone(roomId, zone);
  }

  @override
  Future<void> updateOccupiedSpaces(
    String roomId,
    String zoneId,
    int newCount,
  ) {
    return _firebaseService.updateOccupiedSpaces(roomId, zoneId, newCount);
  }

  @override
  Future<void> deleteParkingZone(String roomId, String zoneId, String userId) {
    return _firebaseService.deleteParkingZone(roomId, zoneId, userId);
  }
}
