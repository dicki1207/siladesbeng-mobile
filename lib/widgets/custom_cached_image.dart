import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomCachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const CustomCachedImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorBuilder?.call(context, 'Empty URL', null) ?? 
             const Icon(Icons.broken_image, color: Colors.grey);
    }

    String finalUrl = url;
    if (finalUrl.startsWith('http://siladesbeng.inovasia.site')) {
      finalUrl = finalUrl.replaceFirst('http://', 'https://');
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      memCacheWidth: 500,
      httpHeaders: const {
        'Referer': 'https://siladesbeng.inovasia.site/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      },
      placeholder: loadingBuilder != null 
          ? (context, url) => loadingBuilder!(context, const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))), null)
          : (context, url) => Container(color: Colors.grey[200]),
      errorWidget: errorBuilder != null 
          ? (context, url, error) => errorBuilder!(context, error, null)
          : (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
