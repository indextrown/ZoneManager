import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonemanager/repositories/room_repository.dart';
import 'package:zonemanager/screens/widgets/room_dialogs.dart';
import 'package:zonemanager/screens/widgets/room_screen_sections.dart';
import 'package:zonemanager/viewmodels/room_view_model.dart';

class RoomScreen extends StatelessWidget {
  final String roomId;
  final String userId;

  const RoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RoomViewModel(
        roomRepository: context.read<RoomRepository>(),
        roomId: roomId,
        userId: userId,
      )..initialize(),
      child: const _RoomScreenView(),
    );
  }
}

class _RoomScreenView extends StatefulWidget {
  const _RoomScreenView();

  @override
  State<_RoomScreenView> createState() => _RoomScreenViewState();
}

class _RoomScreenViewState extends State<_RoomScreenView> {
  final _formKey = GlobalKey<FormState>();
  final _zoneNameController = TextEditingController();
  final _totalSpacesController = TextEditingController();
  Color _selectedColor = const Color(0xFFF5F5F5);

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AddZoneDialog(
        formKey: _formKey,
        zoneNameController: _zoneNameController,
        totalSpacesController: _totalSpacesController,
        selectedColor: _selectedColor,
        onColorChanged: (color) {
          setState(() {
            _selectedColor = color;
          });
        },
        onSubmit: () => _submitZone(dialogContext),
      ),
    );
  }

  Future<void> _submitZone(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<RoomViewModel>();
    final navigator = Navigator.of(dialogContext);
    final messenger = ScaffoldMessenger.of(dialogContext);

    try {
      await viewModel.addParkingZone(
        name: _zoneNameController.text,
        totalSpaces: int.parse(_totalSpacesController.text),
        colorValue: _selectedColor.toARGB32(),
      );
      _zoneNameController.clear();
      _totalSpacesController.clear();
      setState(() {
        _selectedColor = Colors.blue;
      });
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    }
  }

  void _showDeleteRoomDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmDeleteDialog(
        title: '방 삭제',
        message: '정말로 이 방을 삭제하시겠습니까?',
        onConfirm: () => _deleteRoom(dialogContext),
      ),
    );
  }

  Future<void> _deleteRoom(BuildContext dialogContext) async {
    final viewModel = context.read<RoomViewModel>();
    final navigator = Navigator.of(dialogContext);
    final messenger = ScaffoldMessenger.of(dialogContext);

    try {
      await viewModel.deleteRoom();
      navigator.pop();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteZoneDialog(String zoneId, String zoneName) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmDeleteDialog(
        title: '구역 삭제',
        message: '정말로 \'$zoneName\' 구역을 삭제하시겠습니까?',
        onConfirm: () => _deleteZone(dialogContext, zoneId),
      ),
    );
  }

  Future<void> _deleteZone(BuildContext dialogContext, String zoneId) async {
    final viewModel = context.read<RoomViewModel>();
    final navigator = Navigator.of(dialogContext);
    final messenger = ScaffoldMessenger.of(dialogContext);

    try {
      await viewModel.deleteParkingZone(zoneId);
      navigator.pop();
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateOccupiedSpaces(String zoneId, int delta) {
    context.read<RoomViewModel>().updateOccupiedSpaces(zoneId, delta);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoomViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewModel.room?.name ?? '로딩 중...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (viewModel.isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteRoomDialog,
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.42),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null && viewModel.room == null) {
              return Center(child: Text(viewModel.errorMessage!));
            }

            final room = viewModel.room;
            final zones = room?.zones.entries.toList() ?? [];
            // 생성 순서 유지 (zone ID 기준 정렬)
            zones.sort((a, b) => a.key.compareTo(b.key));
            final totalCapacity = zones.fold<int>(
              0,
              (sum, zone) => sum + zone.value.totalSpaces,
            );
            final occupiedCapacity = zones.fold<int>(
              0,
              (sum, zone) => sum + zone.value.occupiedSpaces,
            );
            final availableCapacity = totalCapacity - occupiedCapacity;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                RoomOverviewCard(
                  roomName: room?.name ?? '방 정보',
                  totalCapacity: totalCapacity,
                  occupiedCapacity: occupiedCapacity,
                  availableCapacity: availableCapacity,
                ),
                const SizedBox(height: 18),
                if (room == null || room.zones.isEmpty)
                  const EmptyZoneState()
                else
                  ...zones.map((zoneEntry) {
                    return ZoneCard(
                      zoneId: zoneEntry.key,
                      zone: zoneEntry.value,
                      onDecrease: () => _updateOccupiedSpaces(zoneEntry.key, -1),
                      onIncrease: () => _updateOccupiedSpaces(zoneEntry.key, 1),
                      onDelete: () => _showDeleteZoneDialog(
                        zoneEntry.key,
                        zoneEntry.value.name,
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddZoneDialog,
        child: const Icon(Icons.add_rounded),
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
