import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonemanager/repositories/room_repository.dart';
import 'package:zonemanager/repositories/user_repository.dart';
import 'package:zonemanager/viewmodels/home_view_model.dart';
import 'package:zonemanager/viewmodels/theme_view_model.dart';
import 'room_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(
        roomRepository: context.read<RoomRepository>(),
        userRepository: context.read<UserRepository>(),
      )..initialize(),
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();

  void _createRoom() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<HomeViewModel>();
      try {
        final roomId = await viewModel.createRoom(_roomNameController.text);
        _roomNameController.clear();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomScreen(
              roomId: roomId,
              userId: viewModel.userId!,
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(viewModel.errorMessage ?? '방 생성 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  void _joinRoom(String roomId) {
    final viewModel = context.read<HomeViewModel>();
    if (viewModel.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID 초기화 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(
          roomId: roomId,
          userId: viewModel.userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final homeViewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('주차 관리'),
        actions: [
          IconButton(
            icon: Icon(
              themeViewModel.isDarkMode 
                ? Icons.light_mode 
                : Icons.dark_mode
            ),
            onPressed: () {
              context.read<ThemeViewModel>().toggleTheme();
            },
          ),
        ],
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
                    onPressed: homeViewModel.isCreatingRoom ? null : _createRoom,
                    child: Text(
                      homeViewModel.isCreatingRoom ? '생성 중...' : '방 만들기',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (homeViewModel.errorMessage != null) ...[
              Text(
                homeViewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              '참여 가능한 방',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (homeViewModel.isLoadingRooms || homeViewModel.isInitializingUser) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('데이터를 불러오는 중...'),
                        ],
                      ),
                    );
                  }

                  if (homeViewModel.rooms.isEmpty) {
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
                    itemCount: homeViewModel.rooms.length,
                    itemBuilder: (context, index) {
                      final room = homeViewModel.rooms[index];
                      return Card(
                        child: ListTile(
                          title: Text(room.name),
                          subtitle: Text('구역 수: ${room.zones.length}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
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
