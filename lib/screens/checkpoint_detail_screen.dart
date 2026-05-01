import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';
import '../providers/settings_provider.dart';

class CheckpointDetailScreen extends StatelessWidget {
  final Checkpoint checkpoint;
  final int pathId;

  const CheckpointDetailScreen({
    super.key,
    required this.checkpoint,
    required this.pathId,
  });

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openInMaps(MapProvider provider) async {
    final lat = checkpoint.position.latitude;
    final lng = checkpoint.position.longitude;
    final name = checkpoint.name;

    if (provider == MapProvider.kakao) {
      // Prefer the curated short link if present.
      if (checkpoint.description.kakaoLink != null) {
        await _launchUrl(checkpoint.description.kakaoLink!);
        return;
      }
      // App scheme
      try {
        await launchUrl(
          Uri.parse('kakaomap://look?p=$lat,$lng'),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (_) {}
      await _launchUrl(
          'https://map.kakao.com/?q=${Uri.encodeComponent(name)}&px=$lng&py=$lat');
    } else {
      if (checkpoint.description.naverLink != null) {
        await _launchUrl(checkpoint.description.naverLink!);
        return;
      }
      // App scheme
      try {
        await launchUrl(
          Uri.parse('nmap://place?lat=$lat&lng=$lng'
              '&name=${Uri.encodeComponent(name)}&appname=com.kpedal.app'),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (_) {}
      await _launchUrl('https://map.naver.com/p/search/$lat,$lng');
    }
  }

  Future<void> _searchNearby(MapProvider provider, String keyword) async {
    final lat = checkpoint.position.latitude;
    final lng = checkpoint.position.longitude;
    final encoded = Uri.encodeComponent(keyword);

    if (provider == MapProvider.kakao) {
      try {
        await launchUrl(
          Uri.parse('kakaomap://search?q=$encoded&p=$lat,$lng'),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (_) {}
      await _launchUrl(
          'https://map.kakao.com/?q=$encoded&px=$lng&py=$lat');
    } else {
      try {
        await launchUrl(
          Uri.parse('nmap://search?query=$encoded&lat=$lat&lng=$lng'
              '&zoom=15&appname=com.kpedal.app'),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (_) {}
      await _launchUrl('https://map.naver.com/p/search/$encoded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          checkpoint.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Consumer2<PassportProvider, SettingsProvider>(
        builder: (context, passport, settings, _) {
          final isStamped = passport.isStamped(checkpoint.id);
          final provider = settings.mapProvider;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StampBanner(
                  isStamped: isStamped,
                  onStamp: () => passport.stamp(checkpoint.id),
                  onUnstamp: () => passport.unstamp(checkpoint.id),
                ),
                const SizedBox(height: 20),

                if (checkpoint.description.images.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: checkpoint.description.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: checkpoint.description.images[index],
                            width: 280,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 280,
                              color: const Color(0xFF161B22),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4CAF50),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 280,
                              color: const Color(0xFF161B22),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white38),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const Text(
                  'Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${checkpoint.position.latitude.toStringAsFixed(5)}, '
                  '${checkpoint.position.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Map provider toggle
                _MapProviderToggle(
                  selected: provider,
                  onChanged: (p) => settings.setMapProvider(p),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: _OpenInMapsButton(
                    provider: provider,
                    onTap: () => _openInMaps(provider),
                  ),
                ),

                if (checkpoint.description.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checkpoint.description.text,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Text(
                  'Find Nearby',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opens ${provider == MapProvider.kakao ? 'Kakao' : 'Naver'} Maps near this checkpoint',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _NearbyButton(label: '숙소', sublabel: 'Stay', icon: Icons.hotel, onTap: () => _searchNearby(provider, '숙소 모텔 펜션')),
                    _NearbyButton(label: '편의점', sublabel: 'Store', icon: Icons.store, onTap: () => _searchNearby(provider, '편의점')),
                    _NearbyButton(label: '화장실', sublabel: 'Toilet', icon: Icons.wc, onTap: () => _searchNearby(provider, '공중화장실')),
                    _NearbyButton(label: '자전거수리', sublabel: 'Bike Repair', icon: Icons.build, onTap: () => _searchNearby(provider, '자전거수리')),
                    _NearbyButton(label: '버스정류장', sublabel: 'Bus Stop', icon: Icons.directions_bus, onTap: () => _searchNearby(provider, '버스정류장')),
                    _NearbyButton(label: '기차역', sublabel: 'Train', icon: Icons.train, onTap: () => _searchNearby(provider, '기차역 전철역')),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapProviderToggle extends StatelessWidget {
  final MapProvider selected;
  final ValueChanged<MapProvider> onChanged;

  const _MapProviderToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Kakao Maps',
              selected: selected == MapProvider.kakao,
              activeColor: const Color(0xFFFEE500),
              activeTextColor: Colors.black,
              onTap: () => onChanged(MapProvider.kakao),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ToggleOption(
              label: 'Naver Maps',
              selected: selected == MapProvider.naver,
              activeColor: const Color(0xFF03C75A),
              activeTextColor: Colors.white,
              onTap: () => onChanged(MapProvider.naver),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.activeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeTextColor : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _OpenInMapsButton extends StatelessWidget {
  final MapProvider provider;
  final VoidCallback onTap;

  const _OpenInMapsButton({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isKakao = provider == MapProvider.kakao;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.map, size: 18),
      label: Text(
        'Open in ${isKakao ? 'Kakao' : 'Naver'} Maps',
        style: const TextStyle(fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isKakao ? const Color(0xFFFEE500) : const Color(0xFF03C75A),
        foregroundColor: isKakao ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StampBanner extends StatelessWidget {
  final bool isStamped;
  final VoidCallback onStamp;
  final VoidCallback onUnstamp;

  const _StampBanner({
    required this.isStamped,
    required this.onStamp,
    required this.onUnstamp,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isStamped
            ? const Color(0xFFFFD700).withValues(alpha: 0.12)
            : const Color(0xFFE53935).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStamped
              ? const Color(0xFFFFD700).withValues(alpha: 0.5)
              : const Color(0xFFE53935).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStamped ? Icons.military_tech : Icons.where_to_vote_outlined,
            color: isStamped ? const Color(0xFFFFD700) : const Color(0xFFE53935),
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStamped ? 'Stamped!' : 'Not Stamped Yet',
                  style: TextStyle(
                    color: isStamped ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isStamped
                      ? 'You visited this checkpoint'
                      : 'Visit the red booth to get your stamp',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isStamped ? onUnstamp : onStamp,
            style: TextButton.styleFrom(
              backgroundColor: isStamped
                  ? Colors.white12
                  : const Color(0xFFE53935).withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isStamped ? 'Remove' : 'Stamp!',
              style: TextStyle(
                color: isStamped ? Colors.white54 : const Color(0xFFE53935),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  const _NearbyButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(sublabel,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
