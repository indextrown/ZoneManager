import '../models/room.dart';

abstract class RoomRepository {
  Stream<List<Room>> watchRooms();
  Stream<Room?> watchRoom(String roomId);
  Future<String> createRoom(String name, String creatorId);
  Future<void> deleteRoom(String roomId, String userId);
  Future<void> addParkingZone(String roomId, ParkingZone zone);
  Future<void> updateOccupiedSpaces(
    String roomId,
    String zoneId,
    int newCount,
  );
  Future<void> deleteParkingZone(String roomId, String zoneId, String userId);
}
