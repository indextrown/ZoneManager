import 'package:flutter/material.dart';

import '../../models/room.dart';

class RoomOverviewCard extends StatelessWidget {
  const RoomOverviewCard({
    super.key,
    required this.roomName,
    required this.totalCapacity,
    required this.occupiedCapacity,
    required this.availableCapacity,
  });

  final String roomName;
  final int totalCapacity;
  final int occupiedCapacity;
  final int availableCapacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          // Text(
          //   roomName,
          //   style: theme.textTheme.headlineSmall?.copyWith(
          //     fontWeight: FontWeight.w800,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Text(
          //   '구역별 주차 여유 공간을 실시간으로 확인하고 바로 조정할 수 있어요.',
          //   style: theme.textTheme.bodyMedium?.copyWith(
          //     color: colorScheme.onSurfaceVariant,
          //     height: 1.5,
          //   ),
          // ),
          // const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  label: '총 공간',
                  value: '$totalCapacity',
                  toneColor: colorScheme.primaryContainer,
                  textColor: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  label: '사용 중',
                  value: '$occupiedCapacity',
                  toneColor: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
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
    );
  }
}

class EmptyZoneState extends StatelessWidget {
  const EmptyZoneState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
    );
  }
}

class ZoneCard extends StatelessWidget {
  const ZoneCard({
    super.key,
    required this.zoneId,
    required this.zone,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final String zoneId;
  final ParkingZone zone;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  Color _zoneForegroundColor(Color background) {
    return background.computeLuminance() > 0.58 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
          onLongPress: onDelete,
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
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AdjustButton(
                      icon: Icons.remove_rounded,
                      foreground: foreground,
                      onPressed: onDecrease,
                    ),
                    const SizedBox(width: 10),
                    AdjustButton(
                      icon: Icons.add_rounded,
                      foreground: foreground,
                      onPressed: onIncrease,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
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

class AdjustButton extends StatelessWidget {
  const AdjustButton({
    super.key,
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
