import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/passport_provider.dart';

class CheckpointDetailScreen extends StatelessWidget {
  final Checkpoint checkpoint;
  final int pathId;

  const CheckpointDetailScreen({
    super.key,
    required this.checkpoint,
    required this.pathId,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      body: Consumer<PassportProvider>(
        builder: (context, passport, _) {
          final isStamped = passport.isStamped(checkpoint.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stamp status banner
                _StampBanner(
                  isStamped: isStamped,
                  onStamp: () => passport.stamp(checkpoint.id),
                  onUnstamp: () => passport.unstamp(checkpoint.id),
                ),
                const SizedBox(height: 20),

                // Images
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

                // Location info
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

                const SizedBox(height: 20),

                // Open in maps buttons
                const Text(
                  'Open In Maps',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (checkpoint.description.kakaoLink != null)
                      Expanded(
                        child: _MapButton(
                          label: 'Kakao Maps',
                          icon: Icons.map,
                          color: const Color(0xFFFEE500),
                          textColor: Colors.black,
                          onTap: () => _launchUrl(checkpoint.description.kakaoLink!),
                        ),
                      ),
                    if (checkpoint.description.kakaoLink != null &&
                        checkpoint.description.naverLink != null)
                      const SizedBox(width: 10),
                    if (checkpoint.description.naverLink != null)
                      Expanded(
                        child: _MapButton(
                          label: 'Naver Maps',
                          icon: Icons.map,
                          color: const Color(0xFF03C75A),
                          textColor: Colors.white,
                          onTap: () => _launchUrl(checkpoint.description.naverLink!),
                        ),
                      ),
                    if (checkpoint.description.kakaoLink == null &&
                        checkpoint.description.naverLink == null)
                      Expanded(
                        child: _MapButton(
                          label: 'Open in Maps',
                          icon: Icons.map,
                          color: const Color(0xFF4CAF50),
                          textColor: Colors.white,
                          onTap: () {
                            final lat = checkpoint.position.latitude;
                            final lng = checkpoint.position.longitude;
                            _launchUrl('geo:$lat,$lng?q=$lat,$lng');
                          },
                        ),
                      ),
                  ],
                ),

                // Description text
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

                const SizedBox(height: 40),
              ],
            ),
          );
        },
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
            ? const Color(0xFFFFD700).withOpacity(0.12)
            : const Color(0xFFE53935).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStamped
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : const Color(0xFFE53935).withOpacity(0.3),
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
                  : const Color(0xFFE53935).withOpacity(0.2),
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

class _MapButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _MapButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
