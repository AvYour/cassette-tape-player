import 'dart:math' as math;

/// The look of one stylized cassette spine standing on the shelf.
class SpineLook {
  final int paletteIndex; // which tape palette this spine wears
  final double heightFactor; // 0.82..1.0 — tapes aren't all the same height
  final bool leansLeft; // an occasional tape leans against its neighbour

  const SpineLook({
    required this.paletteIndex,
    required this.heightFactor,
    required this.leansLeft,
  });
}

/// Deterministic shelf dressing: which colors/heights the stylized spines on a
/// playlist's shelf row take. Seeded per playlist so a shelf never reshuffles
/// itself between rebuilds — the room always looks lived-in the same way.
class ShelfLook {
  const ShelfLook._();

  static List<SpineLook> spines({
    required int seed,
    required int count,
    required int paletteSize,
  }) {
    if (count <= 0 || paletteSize <= 0) return const [];
    final rnd = math.Random(seed);
    return List.generate(count, (_) {
      return SpineLook(
        paletteIndex: rnd.nextInt(paletteSize),
        heightFactor: 0.82 + rnd.nextDouble() * 0.18,
        leansLeft: rnd.nextDouble() < 0.08,
      );
    });
  }

  /// How many spines a shelf row shows: every slot filled if the playlist is
  /// big enough, otherwise just the tapes it has.
  static int visibleCount({required int trackCount, required int slots}) {
    if (trackCount <= 0 || slots <= 0) return 0;
    return math.min(trackCount, slots);
  }
}
