import 'package:flutter/material.dart';

const _fruitEmojis = {
  'apple': '🍎',
  'mango': '🥭',
  'banana': '🍌',
  'orange': '🍊',
  'grape': '🍇',
  'grapes': '🍇',
  'watermelon': '🍉',
  'strawberry': '🍓',
  'pineapple': '🍍',
  'lemon': '🍋',
  'peach': '🍑',
  'pear': '🍐',
  'cherry': '🍒',
  'cherries': '🍒',
  'melon': '🍈',
  'kiwi': '🥝',
  'coconut': '🥥',
  'blueberry': '🫐',
  'blueberries': '🫐',
  'avocado': '🥑',
  'tomato': '🍅',
  'pomegranate': '🍎',
  'fig': '🍑',
  'date': '🌴',
  'dates': '🌴',
  'guava': '🍐',
  'papaya': '🥭',
  'plum': '🍑',
  'apricot': '🍑',
  'lychee': '🍇',
};

String fruitEmoji(String fruitName) {
  final key = fruitName.toLowerCase().trim();
  for (final entry in _fruitEmojis.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return '🍈';
}

/// Returns the local asset path for a fruit icon if it exists,
/// otherwise null (caller should fall back to [fruitEmoji]).
// Maps fruit name variants → actual filename (without .png)
const _fruitAssetNames = {
  'grape': 'grapes',       // singular → plural file
  'pears': 'pear',         // plural → singular file
  'cherries': 'cherry',    // plural → singular file
  'exoticfruits': 'exoticfruits',
  'mandarin': 'orange',    // mandarin → orange icon
  'tangerine': 'orange',
  'clementine': 'orange',
};

String fruitAssetPath(String fruitName) {
  final key = fruitName.toLowerCase().trim().replaceAll(' ', '');
  final mapped = _fruitAssetNames[key] ?? key;
  return 'assets/icons/fruits/$mapped.png';
}

// Per-fruit scale overrides for assets that have extra whitespace.
const _fruitScales = {
  'dragonfruit': 1.55,
  'plum': 1.55,
};

/// A widget that shows a fruit icon with priority:
/// 1. [bannerUrl] from Firestore (if provided and non-empty)
/// 2. Local 3D asset from assets/icons/fruits/
/// 3. Emoji fallback
class FruitIcon extends StatelessWidget {
  final String fruitName;
  final double size;
  final String? bannerUrl;

  const FruitIcon({super.key, required this.fruitName, this.size = 36, this.bannerUrl});

  @override
  Widget build(BuildContext context) {
    if (bannerUrl != null && bannerUrl!.isNotEmpty) {
      return Image.network(
        bannerUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localAsset(),
      );
    }
    return _localAsset();
  }

  Widget _localAsset() {
    final key = fruitName.toLowerCase().trim().replaceAll(' ', '');
    final scale = _fruitScales[key] ?? 1.0;
    final img = Image.asset(
      fruitAssetPath(fruitName),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        fruitEmoji(fruitName),
        style: TextStyle(fontSize: size * 0.75),
      ),
    );
    if (scale == 1.0) return img;
    return Transform.scale(scale: scale, child: img);
  }
}
