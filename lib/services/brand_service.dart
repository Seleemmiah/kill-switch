import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandService {
  static Map<String, dynamic> resolveBrand(String name) {
    final n = name.toLowerCase();

    if (n.contains('netflix')) {
      return {
        'logo': 'assets/netflix.png',
        'color': const Color(0xFFE50914),
        'icon': Icons.movie_filter_rounded,
      };
    }
    if (n.contains('spotify')) {
      return {
        'logo': 'assets/spotify.png',
        'color': const Color(0xFF1DB954),
        'icon': Icons.music_note_rounded,
      };
    }
    if (n.contains('apple music')) {
      return {
        'logo': 'assets/music.png',
        'color': const Color(0xFFFA243C),
        'icon': Icons.music_note_rounded,
      };
    }
    if (n.contains('icloud') || n.contains('apple')) {
      return {
        'logo': 'assets/apple-logo.png',
        'color': const Color(0xFF000000),
        'icon': Icons.cloud_rounded,
      };
    }
    if (n.contains('chatgpt') || n.contains('openai')) {
      return {
        'logo': 'assets/chatgpt.png',
        'color': const Color(0xFF10A37F),
        'icon': Icons.smart_toy_rounded,
      };
    }
    if (n.contains('youtube') || n.contains('google')) {
      return {
        'logo': n.contains('youtube')
            ? 'assets/youtube.png'
            : 'assets/google.png',
        'color': n.contains('youtube')
            ? const Color(0xFFFF0000)
            : const Color(0xFF4285F4),
        'icon': Icons.play_circle_fill_rounded,
      };
    }
    if (n.contains('xd') || n.contains('adobe') || n.contains('lightroom')) {
      return {
        'logo': n.contains('xd')
            ? 'assets/xd.png'
            : (n.contains('lightroom')
                  ? 'assets/photoshop-lightroom.png'
                  : 'assets/logo.png'),
        'color': n.contains('xd')
            ? const Color(0xFFFF0000)
            : const Color(0xFFFA0F00),
        'icon': Icons.design_services_rounded,
      };
    }
    if (n.contains('prime') || n.contains('amazon')) {
      return {
        'logo': 'assets/amazon prime.png',
        'color': const Color(0xFF00A8E1),
        'icon': Icons.movie_filter_rounded,
      };
    }
    if (n.contains('canva')) {
      return {
        'color': const Color(0xFF00C4CC),
        'icon': Icons.design_services_rounded,
      };
    }
    if (n.contains('hulu')) {
      return {'color': const Color(0xFF1CE783), 'icon': Icons.tv_rounded};
    }
    if (n.contains('paramount')) {
      return {
        'logo': 'assets/paramount+.jpeg',
        'color': const Color(0xFF0064FF),
        'icon': Icons.movie_filter_rounded,
      };
    }
    if (n.contains('x premium') || n == 'x' || n.contains('twitter')) {
      return {
        'logo': 'assets/twitter.png',
        'color': const Color(0xFF000000),
        'icon': Icons.close_rounded,
      };
    }
    if (n.contains('audible')) {
      return {
        'logo': 'assets/audible.png',
        'color': const Color(0xFFF5D000),
        'icon': Icons.audiotrack_rounded,
      };
    }

    if (n.contains('zoho')) {
      return {'color': const Color(0xFFE31B23), 'icon': Icons.business_rounded};
    }

    return {
      'logo': null,
      'color': AppTheme.gold,
      'icon': Icons.subscriptions_rounded,
    };
  }
}
