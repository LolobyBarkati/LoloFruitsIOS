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
  'grape': 'grapes', // singular → plural file
  'pears': 'pear', // plural → singular file
  'cherries': 'cherry', // plural → singular file
  'otherfruit': 'otherfruits',
  'exoticfruits': 'otherfruits',
  'mandarin': 'orange', // mandarin → orange icon
  'tangerine': 'orange',
  'clementine': 'orange',
  'dragon': 'dragon',
  'avcado': 'avacado',
  'avacado': 'avacado',
  'dates': 'dates',
};

String fruitAssetPath(String fruitName) {
  final key = fruitName.toLowerCase().trim().replaceAll(' ', '');
  final mapped = _fruitAssetNames[key] ?? key;
  return 'assets/icons/fruits/$mapped.png';
}

/// A widget that shows a fruit icon with priority:
/// 1. [bannerUrl] from Firestore (if provided and non-empty)
/// 2. Local 3D asset from assets/icons/fruits/
/// 3. Emoji fallback
class FruitIcon extends StatelessWidget {
  final String fruitName;
  final double size;
  final String? bannerUrl;

  const FruitIcon(
      {super.key, required this.fruitName, this.size = 36, this.bannerUrl});

  double _getAdjustedSize() {
    final key = fruitName.toLowerCase().trim();
    if (key.contains('dragonfruit') || key.contains('dragon') || key.contains('plum')) {
      return size * 1.55;
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final adjustedSize = _getAdjustedSize();
    if (bannerUrl != null && bannerUrl!.isNotEmpty) {
      return Image.network(
        bannerUrl!,
        width: adjustedSize,
        height: adjustedSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localAsset(adjustedSize),
      );
    }
    return _localAsset(adjustedSize);
  }

  Widget _localAsset(double adjustedSize) {
    return Image.asset(
      fruitAssetPath(fruitName),
      width: adjustedSize,
      height: adjustedSize,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        fruitEmoji(fruitName),
        style: TextStyle(fontSize: adjustedSize * 0.75),
      ),
    );
  }
}