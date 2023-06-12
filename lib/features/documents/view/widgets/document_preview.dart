import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DocumentPreview extends StatelessWidget {
  final DocumentModel document;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;
  final bool enableHero;
  final double scale;

  const DocumentPreview({
    super.key,
    required this.document,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.borderRadius = 12.0,
    this.enableHero = true,
    this.scale = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: enableHero,
      child: Hero(
        tag: "thumb_${document.id}",
        child: _buildPreview(context),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Transform.scale(
        scale: scale,
        child: CachedNetworkImage(
          fit: fit,
          alignment: alignment,
          cacheKey: "thumb_${document.id}",
          imageUrl: context
              .read<PaperlessDocumentsApi>()
              .getThumbnailUrl(document.id),
          errorWidget: (ctxt, msg, __) => Text(msg),
          placeholder: (context, value) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: const SizedBox(height: 100, width: 100),
          ),
          cacheManager: context.watch<CacheManager>(),
        ),
      ),
    );
  }
}
