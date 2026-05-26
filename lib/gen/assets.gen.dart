import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Assets {
  static const Images images = Images();
}

class Images {
  const Images();
  final AssetGenImage backgroundImage = const AssetGenImage('assets/images/background.png');
  final IconsAssets icons = const IconsAssets();
}

class IconsAssets {
  const IconsAssets();
  final SvgGenImage backIcon = const SvgGenImage('assets/icons/back.svg');
}

class SvgGenImage {
  const SvgGenImage(this._assetName);
  final String _assetName;

  Widget svg({
    double? width,
    double? height,
    ColorFilter? colorFilter,
  }) {
    return Icon(
      Icons.arrow_forward, // Dummy icon
      size: width,
      color: colorFilter != null ? Colors.black : null, // Simplistic dummy
    );
  }
}

class AssetGenImage {
  const AssetGenImage(this._assetName);
  final String _assetName;

  Image image({
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    // Return a dummy placeholder or empty container if image missing
    return Image.network(
      'https://via.placeholder.com/1', // Minimal dummy
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Container(),
    );
  }
}
