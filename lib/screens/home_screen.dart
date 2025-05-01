import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import 'room_screen.dart';
import 'package:logging/logging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _log = Logger('HomeScreen');
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initUserId();
  }

  Future<void> _initUserId() async {
    final userService = await UserService.getInstance();
    _userId = await userService.getUserId();
    _log.info('사용자 ID 초기화: $_userId');
  }

  void _createRoom() async {
    if (_userId == null) {
      _log.severe('사용자 ID가 초기화되지 않음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID 초기화 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _log.info('방 생성 시도: ${_roomNameController.text}');
      try {
        final roomId = await _firebaseService.createRoom(_roomNameController.text, _userId!);
        _roomNameController.clear();
        if (mounted) {
          _log.info('방 생성 성공: $roomId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomScreen(
                roomId: roomId,
                userId: _userId!,
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        _log.severe('방 생성 실패', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('방 생성 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  void _joinRoom(String roomId) {
    if (_userId == null) {
      _log.severe('사용자 ID가 초기화되지 않음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID 초기화 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    _log.info('방 참여: $roomId');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          roomId: roomId,
          userId: _userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주차 관리자'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(
                      labelText: '방 이름',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '방 이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createRoom,
                    child: const Text('방 만들기'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '참여 가능한 방',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: _firebaseService.getRooms(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text('오류가 발생했습니다\n${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('방 목록을 불러오는 중...'),
                        ],
                      ),
                    );
                  }

                  final rooms = snapshot.data ?? [];

                  if (rooms.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('참여 가능한 방이 없습니다'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return Card(
                        child: ListTile(
                          title: Text(room.name),
                          subtitle: Text('구역 수: ${room.zones.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                          onTap: () => _joinRoom(room.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }
} 