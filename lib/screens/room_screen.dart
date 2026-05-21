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
              final parentNavigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(dialogContext);

              try {
                await viewModel.deleteRoom();
                navigator.pop(); // 다이얼로그 닫기
                parentNavigator.pop(); // 화면 닫기
              } catch (e) {
                navigator.pop(); // 에러 발생 시에도 다이얼로그는 닫기
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoomViewModel>();

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
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.room == null) {
            return Center(child: Text(viewModel.errorMessage!));
          }

          final room = viewModel.room;
          if (room == null || room.zones.isEmpty) {
            return const Center(child: Text('등록된 구역이 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: room.zones.length,
            itemBuilder: (context, index) {
              final zoneEntry = room.zones.entries.elementAt(index);
              final zone = zoneEntry.value;
              final availableSpaces = zone.totalSpaces - zone.occupiedSpaces;
              
              return Card(
                elevation: 2,
                color: zone.color != 0 ? Color(zone.color) : null,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '사용 중: ${zone.occupiedSpaces}/${zone.totalSpaces}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '남은 공간: $availableSpaces',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: availableSpaces == 0 
                                      ? Colors.red 
                                      : availableSpaces < zone.totalSpaces * 0.2 
                                        ? Colors.orange 
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateOccupiedSpaces(
                                    zoneEntry.key,
                                    -1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateOccupiedSpaces(
                                    zoneEntry.key,
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
