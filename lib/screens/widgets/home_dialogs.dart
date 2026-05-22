import 'package:flutter/material.dart';

class CreateRoomDialog extends StatelessWidget {
  const CreateRoomDialog({
    super.key,
    required this.formKey,
    required this.roomNameController,
    required this.onCreate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController roomNameController;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('새 방 만들기'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: roomNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '방 이름',
            hintText: '예: 본당 주차장 / 1층 운영실',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '방 이름을 입력해주세요';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_circle_outline_rounded),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          label: const Text('생성'),
        ),
      ],
    );
  }
}
