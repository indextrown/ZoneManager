import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/firebase_service.dart';
import 'package:logging/logging.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;

  const RoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _zoneNameController = TextEditingController();
  final _totalSpacesController = TextEditingController();
  final _log = Logger('RoomScreen');

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('구역 추가'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _zoneNameController,
                decoration: const InputDecoration(
                  labelText: '구역 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '구역 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalSpacesController,
                decoration: const InputDecoration(
                  labelText: '총 주차 공간',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주차 공간 수를 입력해주세요';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return '올바른 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final zone = ParkingZone(
                  name: _zoneNameController.text,
                  totalSpaces: int.parse(_totalSpacesController.text),
                );

                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(dialogContext);

                try {
                  await _firebaseService.addParkingZone(widget.roomId, zone);
                  _zoneNameController.clear();
                  _totalSpacesController.clear();
                  navigator.pop();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: $e')),
                  );
                }
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoomDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('방 삭제'),
        content: const Text('정말로 이 방을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final parentNavigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(dialogContext);

              try {
                _log.info('방 삭제 시도 - userId: ${widget.userId}');
                await _firebaseService.deleteRoom(widget.roomId, widget.userId);
                navigator.pop(); // 다이얼로그 닫기
                parentNavigator.pop(); // 화면 닫기
              } catch (e) {
                navigator.pop(); // 에러 발생 시에도 다이얼로그는 닫기
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showDeleteZoneDialog(String zoneId, String zoneName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('구역 삭제'),
        content: Text('정말로 \'$zoneName\' 구역을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(dialogContext);

              try {
                await _firebaseService.deleteParkingZone(
                  widget.roomId,
                  zoneId,
                  widget.userId,
                );
                navigator.pop();
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _updateOccupiedSpaces(String zoneId, int currentCount, int totalSpaces, int delta) {
    final newCount = currentCount + delta;
    if (newCount >= 0 && newCount <= totalSpaces) {
      _firebaseService.updateOccupiedSpaces(widget.roomId, zoneId, newCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: _firebaseService.getRoom(widget.roomId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('로딩 중...');
            final room = snapshot.data!;
            final isCreator = room.creatorId == widget.userId;
            _log.info('방 정보 - roomId: ${widget.roomId}, creatorId: ${room.creatorId}, userId: ${widget.userId}, isCreator: $isCreator');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(room.name, textAlign: TextAlign.center),
                ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _showDeleteRoomDialog,
                  ),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _firebaseService.getRoom(widget.roomId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = snapshot.data!;
          if (room.zones.isEmpty) {
            return const Center(child: Text('등록된 구역이 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: room.zones.length,
            itemBuilder: (context, index) {
              final zoneEntry = room.zones.entries.elementAt(index);
              final zone = zoneEntry.value;
              return Card(
                child: InkWell(
                  onLongPress: () => _showDeleteZoneDialog(zoneEntry.key, zone.name),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${zone.occupiedSpaces}/${zone.totalSpaces}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateOccupiedSpaces(
                                    zoneEntry.key,
                                    zone.occupiedSpaces,
                                    zone.totalSpaces,
                                    -1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateOccupiedSpaces(
                                    zoneEntry.key,
                                    zone.occupiedSpaces,
                                    zone.totalSpaces,
                                    1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddZoneDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    _totalSpacesController.dispose();
    super.dispose();
  }
}
