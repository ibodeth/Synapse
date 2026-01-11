
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'glass_container.dart';

class InfoOverlay extends StatelessWidget {
  const InfoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          

          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
          

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                color: Colors.black.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Text(
                        "Synapse",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Geliştirici Hakkında",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSocialLink(
                        icon: FontAwesomeIcons.youtube,
                        text: "YouTube",
                        color: const Color(0xFFFF0000),
                        url: "https://www.youtube.com/@ibrahim.python",
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSocialLink(
                        icon: FontAwesomeIcons.github,
                        text: "GitHub",
                        color: Colors.white,
                        url: "https://github.com/ibodeth",
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSocialLink(
                        icon: FontAwesomeIcons.globe,
                        text: "Web Sitesi",
                        color: const Color(0xFF2196F3),
                        url: "https://ibodeth.github.io/",
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSocialLink(
                        icon: FontAwesomeIcons.linkedin,
                        text: "LinkedIn",
                        color: const Color(0xFF0077B5),
                        url: "https://www.linkedin.com/in/ibrahimnuryaginli/",
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        "v1.0.0",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink({
    required IconData icon,
    required String text,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
