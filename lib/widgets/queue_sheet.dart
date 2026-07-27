import 'package:flutter/material.dart';
import '../models/cassette_tape.dart';
import '../utils/explore_theme.dart';
import 'glass.dart';
import 'track_row.dart';

/// The rest of the tape: what is playing now and what follows. Tapping a row
/// jumps straight to it rather than pressing next until you arrive.
class QueueSheet extends StatelessWidget {
  final List<CassetteTape> queue;
  final int index;
  final void Function(int index) onJump;

  const QueueSheet({
    super.key,
    required this.queue,
    required this.index,
    required this.onJump,
  });

  static void show(
    BuildContext context, {
    required List<CassetteTape> queue,
    required int index,
    required void Function(int index) onJump,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QueueSheet(queue: queue, index: index, onJump: onJump),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show the current tape plus everything after it; the ones already played
    // are behind you.
    final upcoming = <int>[
      for (var i = index; i < queue.length; i++) i,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: GlassPanel(
        radius: 24,
        fill: 0.6,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Explore.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'UP NEXT · ${upcoming.length} of ${queue.length}',
                style: Explore.caption.copyWith(letterSpacing: 1.5),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: upcoming.length,
                itemBuilder: (context, row) {
                  final i = upcoming[row];
                  return TrackRow(
                    tape: queue[i],
                    nowPlaying: i == index,
                    onTap: () {
                      Navigator.pop(context);
                      if (i != index) onJump(i);
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
}
