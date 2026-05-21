import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonemanager/repositories/room_repository.dart';
import 'package:zonemanager/viewmodels/room_view_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  Color _selectedColor = const Color(0xFFF5F5F5); // 기본 색상을 연한 회색으로 변경

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }

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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.color_lens, color: _selectedColor),
                label: const Text('색상 선택'),
                onPressed: _showColorPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
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
                    _selectedColor = Colors.blue; // 색상 초기화
                  });
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

  void _updateOccupiedSpaces(String zoneId, int delta) {
    context.read<RoomViewModel>().updateOccupiedSpaces(zoneId, delta);
  }

  Color _zoneForegroundColor(Color background) {
    return background.computeLuminance() > 0.58 ? Colors.black87 : Colors.white;
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
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room?.name ?? '방 정보',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '구역별 주차 여유 공간을 실시간으로 확인하고 바로 조정할 수 있어요.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: '총 공간',
                              value: '$totalCapacity',
                              toneColor: colorScheme.primaryContainer,
                              textColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryTile(
                              label: '사용 중',
                              value: '$occupiedCapacity',
                              toneColor: colorScheme.secondaryContainer,
                              textColor: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryTile(
                              label: '여유',
                              value: '$availableCapacity',
                              toneColor: colorScheme.tertiaryContainer,
                              textColor: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (room == null || room.zones.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 42,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '등록된 구역이 없습니다',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '오른쪽 아래 버튼으로 첫 구역을 추가해보세요.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...zones.map((zoneEntry) {
                    final zone = zoneEntry.value;
                    final availableSpaces = zone.totalSpaces - zone.occupiedSpaces;
                    final progress = zone.totalSpaces == 0
                        ? 0.0
                        : zone.occupiedSpaces / zone.totalSpaces;
                    final background = zone.color != 0
                        ? Color(zone.color)
                        : colorScheme.surfaceContainerHigh;
                    final foreground = _zoneForegroundColor(background);
                    final mutedForeground = foreground.withValues(alpha: 0.78);
                    final progressColor = availableSpaces == 0
                        ? const Color(0xFFB91C1C)
                        : availableSpaces < zone.totalSpaces * 0.2
                            ? const Color(0xFFD97706)
                            : const Color(0xFF15803D);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onLongPress: () => _showDeleteZoneDialog(zoneEntry.key, zone.name),
                          child: Ink(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        zone.name,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: foreground.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '여유 $availableSpaces',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '사용 중 ${zone.occupiedSpaces} / 전체 ${zone.totalSpaces}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: foreground.withValues(alpha: 0.16),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _AdjustButton(
                                      icon: Icons.remove_rounded,
                                      foreground: foreground,
                                      onPressed: () => _updateOccupiedSpaces(
                                        zoneEntry.key,
                                        -1,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _AdjustButton(
                                      icon: Icons.add_rounded,
                                      foreground: foreground,
                                      onPressed: () => _updateOccupiedSpaces(
                                        zoneEntry.key,
                                        1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.toneColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color toneColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: toneColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.icon,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: foreground.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: foreground),
        ),
      ),
    );
  }
}
