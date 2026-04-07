import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _call(String number) async {
    try {
      await launchUrl(Uri.parse('tel:$number'),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _searchNearby(String keyword) async {
    // Try Kakao Maps app (uses device GPS for nearby search)
    try {
      await launchUrl(
        Uri.parse('kakaomap://search?q=${Uri.encodeComponent(keyword)}'),
        mode: LaunchMode.externalApplication,
      );
      return;
    } catch (_) {}
    // Fallback: Kakao Maps web
    try {
      await launchUrl(
        Uri.parse('https://map.kakao.com/?q=${Uri.encodeComponent(keyword)}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Travel Info',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Contacts
            _SectionHeader(
              icon: Icons.emergency,
              label: 'Emergency Contacts',
              color: const Color(0xFFE53935),
            ),
            const SizedBox(height: 12),
            _EmergencyButton(
              number: '119',
              label: 'Emergency (Fire / Ambulance)',
              sublabel: '소방서 / 구급대',
              color: const Color(0xFFE53935),
              icon: Icons.local_fire_department,
              onTap: () => _call('119'),
            ),
            const SizedBox(height: 8),
            _EmergencyButton(
              number: '112',
              label: 'Police',
              sublabel: '경찰서',
              color: const Color(0xFF2196F3),
              icon: Icons.local_police,
              onTap: () => _call('112'),
            ),
            const SizedBox(height: 8),
            _EmergencyButton(
              number: '1330',
              label: 'Korea Tourism Hotline',
              sublabel: '한국관광공사 (English OK)',
              color: const Color(0xFF4CAF50),
              icon: Icons.info_outline,
              onTap: () => _call('1330'),
            ),

            const SizedBox(height: 28),

            // Find Nearby
            _SectionHeader(
              icon: Icons.search,
              label: 'Find Nearby',
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 4),
            const Text(
              'Opens Kakao Maps near your current location',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _NearbyTile(
                  label: '숙소',
                  sublabel: 'Stay',
                  icon: Icons.hotel,
                  onTap: () => _searchNearby('숙소 모텔 펜션'),
                ),
                _NearbyTile(
                  label: '편의점',
                  sublabel: 'Convenience',
                  icon: Icons.store,
                  onTap: () => _searchNearby('편의점'),
                ),
                _NearbyTile(
                  label: '화장실',
                  sublabel: 'Toilet',
                  icon: Icons.wc,
                  onTap: () => _searchNearby('공중화장실'),
                ),
                _NearbyTile(
                  label: '자전거수리',
                  sublabel: 'Bike Repair',
                  icon: Icons.build,
                  onTap: () => _searchNearby('자전거수리'),
                ),
                _NearbyTile(
                  label: '버스정류장',
                  sublabel: 'Bus Stop',
                  icon: Icons.directions_bus,
                  onTap: () => _searchNearby('버스정류장'),
                ),
                _NearbyTile(
                  label: '기차역',
                  sublabel: 'Train / Subway',
                  icon: Icons.train,
                  onTap: () => _searchNearby('기차역 전철역 지하철역'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // About K-Pedal
            _SectionHeader(
              icon: Icons.pedal_bike,
              label: 'About K-Pedal',
              color: Colors.white54,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'K-Pedal is a cycling passport app for Korea\'s national bike certification routes (국토종주 자전거길). '
                'Collect stamps at red certification booths along the way. '
                'Complete a full route to earn your official certificate.\n\n'
                'Routes include the Han River, Nakdong River, 4 Rivers, and more.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Credits
            Center(
              child: Column(
                children: [
                  const Text(
                    'Made by',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await launchUrl(
                          Uri.parse('https://www.gapp.in'),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                    child: const Text(
                      'Gapp',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'www.gapp.in',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String number;
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _EmergencyButton({
    required this.number,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(sublabel,
                      style: TextStyle(color: color, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  const _NearbyTile({
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
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(sublabel,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
