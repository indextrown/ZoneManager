import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonemanager/repositories/room_repository.dart';
import 'package:zonemanager/repositories/user_repository.dart';
import 'package:zonemanager/viewmodels/home_view_model.dart';
import 'package:zonemanager/viewmodels/theme_view_model.dart';
import 'package:zonemanager/screens/widgets/home_dialogs.dart';
import 'package:zonemanager/screens/widgets/home_screen_sections.dart';
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

  void _showCreateRoomDialog() {
    _roomNameController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => CreateRoomDialog(
        formKey: _formKey,
        roomNameController: _roomNameController,
        onCreate: _createRoom,
      ),
    );
  }

  void _createRoom() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<HomeViewModel>();
      try {
        final roomId = await viewModel.createRoom(_roomNameController.text);
        _roomNameController.clear();
        if (!mounted) return;
        Navigator.of(context).pop();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Manager'),
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
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showCreateRoomDialog,
            tooltip: '새 방 만들기',
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.55),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeViewModel>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              HomeHeroCard(roomCount: homeViewModel.rooms.length),
              const SizedBox(height: 20),
              if (homeViewModel.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    homeViewModel.errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              HomeRoomsSection(
                rooms: homeViewModel.rooms,
                isLoading: homeViewModel.isLoadingRooms ||
                    homeViewModel.isInitializingUser,
                onCreateRoom: _showCreateRoomDialog,
                onJoinRoom: _joinRoom,
              ),
            ],
          ),
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
