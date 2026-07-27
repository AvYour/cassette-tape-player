import 'package:flutter/material.dart';
import '../models/browse.dart';
import '../utils/explore_theme.dart';

/// One album in a list: square cover, name, artist, chevron. Shared by search,
/// artist pages and saved albums so an album always looks the same.
class AlbumListRow extends StatelessWidget {
  final AlbumBrief album;
  final VoidCallback onTap;
  final bool showArtist;

  const AlbumListRow({
    super.key,
    required this.album,
    required this.onTap,
    this.showArtist = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: album.imageUrl == null
                        ? Container(color: Explore.hairline)
                        : Image.network(album.imageUrl!,
                            fit: BoxFit.cover, cacheWidth: 150),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Explore.rowTitle.copyWith(fontSize: 15.5)),
                      if (showArtist && album.artistName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(album.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Explore.rowOwner.copyWith(fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Explore.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One artist in a list: round photo, name, chevron. Shared by search, the
/// empty search screen and the following list.
class ArtistListRow extends StatelessWidget {
  final ArtistBrief artist;
  final VoidCallback onTap;

  const ArtistListRow({super.key, required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: artist.imageUrl == null
                        ? Container(color: Explore.hairline)
                        : Image.network(artist.imageUrl!,
                            fit: BoxFit.cover, cacheWidth: 150),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Explore.rowTitle.copyWith(fontSize: 15.5)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Explore.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
