// Trigger re-analysis
library honeycomb_people_core;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:math';

// ===== AYARLAMA PARAMETRELERİ (Tuning Parameters) =====
class HoneycombConfig {
  // Bubble boyut ve görünüm ayarları
  final double baseBubbleSize; // Ana bubble boyutu
  final double maxBubbleSize; // Maksimum bubble boyutu
  final double minBubbleSize; // Minimum bubble boyutu

  // Mesafe ve ölçekleme ayarları
  final double falloffRadius; // Ölçeklendirme mesafe etkisi
  final double activeBubbleFalloff; // Aktif bubble için mesafe etkisi
  final double hoverScaleBoost; // Hover ek büyütme
  final double maxBlurDistance; // Maksimum blur mesafesi
  final double maxBlurSigma; // Maksimum blur şiddeti

  // Grid layout ayarları
  final double hexSpacing; // Altıgen grid aralığı
  final double ringSpacing; // Ring arası çarpan
  final int maxRings; // Maksimum ring sayısı

  // Animasyon ayarları
  final Duration animationDuration;
  final Curve animationCurve;

  // Text arka plan ayarları
  final double nameBackgroundOpacity; // İsim arka plan şeffaflığı
  final Color nameBackgroundColor; // İsim arka plan rengi
  final double nameBackgroundRadius; // İsim arka plan border radius

  // Arc text arka plan ayarları
  final bool showArcBackground; // Arc arka plan göster/gizle
  final Color arcBackgroundColor; // Arc arka plan rengi
  final double arcBackgroundOpacity; // Arc arka plan şeffaflığı

  const HoneycombConfig({
    this.baseBubbleSize = 90.0,
    this.maxBubbleSize = 130.0,
    this.minBubbleSize = 40.0,
    this.falloffRadius = 100.0,
    this.activeBubbleFalloff = 80.0,
    this.hoverScaleBoost = 1.15,
    this.maxBlurDistance = 300.0,
    this.maxBlurSigma = 8.0,
    this.hexSpacing = 60.0,
    this.ringSpacing = 1.4,
    this.maxRings = 4,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutQuart,
    this.nameBackgroundOpacity = 0.6,
    this.nameBackgroundColor = Colors.black,
    this.nameBackgroundRadius = 12.0,
    this.showArcBackground = true,
    this.arcBackgroundColor = Colors.black,
    this.arcBackgroundOpacity = 0.4,
  });
}

// ===== VERİ MODELİ =====
class Contributor {
  final String name;
  final String role;
  final String? photoUrl;

  const Contributor({
    required this.name,
    required this.role,
    this.photoUrl,
  });
}

// Bubble pozisyon ve veri bilgisi için yardımcı class
class _BubbleData {
  final Contributor contributor;
  final Offset position;
  final int index;

  _BubbleData({
    required this.contributor,
    required this.position,
    required this.index,
  });
}

// ===== ÖRNEK VERİLER =====
final List<Contributor> sampleContributors = [
  const Contributor(
      name: "Mehmet Özkan",
      role: "Senior Flutter Developer",
      photoUrl:
          "https://kivomobileproadmin.maptriks.com/ApplicationFiles/IconCatalog/B2EB007337A6AF2EE987F271D1699118.png"),
  const Contributor(
      name: "Ayşe Demir",
      role: "UI/UX Designer",
      photoUrl: null // İnisiyaller için test
      ),
  const Contributor(
      name: "Ali Yılmaz",
      role: "Backend Developer",
      photoUrl:
          "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=facearea&w=200&h=200"),
  const Contributor(
      name: "Fatma Çelik",
      role: "Product Owner",
      photoUrl:
          "https://fastly.picsum.photos/id/243/200/200.jpg?hmac=fW5ZwzzyTBy2t2MROp988oq12mZnKwN0coFLhZEE87s"),
  const Contributor(
      name: "Gökalp Köseoğlu",
      role: "Product Manager",
      photoUrl: null // İnisiyaller için test
      ),
  const Contributor(
      name: "Zehra Şahin",
      role: "QA Engineer",
      photoUrl: "https://randomuser.me/api/portraits/women/15.jpg"),
  const Contributor(
      name: "Oğuz Türkmen",
      role: "Mobile Developer",
      photoUrl: "https://randomuser.me/api/portraits/men/3.jpg"),
  const Contributor(
      name: "İrem Avcı",
      role: "Frontend Developer",
      photoUrl: null // İnisiyaller için test
      ),
  const Contributor(
      name: "Burak Güneş",
      role: "Data Scientist",
      photoUrl: "https://picsum.photos/200/200?random=6"),
  const Contributor(
      name: "Selin Koç",
      role: "Scrum Master",
      photoUrl: "https://randomuser.me/api/portraits/women/52.jpg"),
  const Contributor(
      name: "Cem Öztürk",
      role: "Tech Lead",
      photoUrl: "https://randomuser.me/api/portraits/men/72.jpg"),
  const Contributor(
      name: "Neslihan Aktaş",
      role: "Business Analyst",
      photoUrl: null // İnisiyaller için test
      ),
  const Contributor(
      name: "Murat Kaya",
      role: "Security Engineer",
      photoUrl: "https://randomuser.me/api/portraits/men/32.jpg"),
  const Contributor(
      name: "Elif Doğan",
      role: "Marketing Manager",
      photoUrl: "https://randomuser.me/api/portraits/women/41.jpg"),
  const Contributor(
      name: "Serkan Ünal",
      role: "Cloud Architect",
      photoUrl:
          "https://www.maptriks.com/wp-content/uploads/2022/07/maptriks-yonetici-ortak-fatih-kuralkan.jpg"),
  const Contributor(
      name: "Pınar Çakır",
      role: "Content Writer",
      photoUrl: null // İnisiyaller için test
      ),
];

class ContributorsScreen extends StatefulWidget {
  final List<Contributor> contributors;
  final HoneycombConfig config;

  const ContributorsScreen({
    super.key,
    required this.contributors,
    this.config = const HoneycombConfig(),
  });

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen>
    with TickerProviderStateMixin {
  // Odak noktası koordinatları
  final ValueNotifier<Offset> focusPoint = ValueNotifier(Offset.zero);

  // Hover durumu için
  final ValueNotifier<int?> hoveredIndex = ValueNotifier(null);

  // Animasyon controller
  late AnimationController animationController;

  // Grid pozisyonları cache
  List<Offset> gridPositions = [];

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    focusPoint.dispose();
    hoveredIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Honeycomb People'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ekran merkezi hesaplama
          final center =
              Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

          // İlk kez odak noktasını merkeze ayarla
          if (focusPoint.value == Offset.zero) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusPoint.value = center;
            });
          }

          // Grid pozisyonlarını hesapla
          gridPositions = _generateHexGridPositions(center, constraints);

          return MouseRegion(
            onHover: (event) {
              // Web için mouse pozisyonunu takip et
              focusPoint.value = event.localPosition;
            },
            child: GestureDetector(
              onPanUpdate: (details) {
                // Mobil için touch pozisyonunu takip et
                focusPoint.value = details.localPosition;
              },
              onTap: () {
                // Boş alan tıklandığında focus'u merkeze döndür
                focusPoint.value = center;
              },
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Arka plan
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF1a1a2e),
                            Color(0xFF16213e),
                            Color(0xFF0f0f23),
                          ],
                        ),
                      ),
                    ),

                    // Bubble'lar - z-order'a göre sıralanmış
                    ValueListenableBuilder<int?>(
                      valueListenable: hoveredIndex,
                      builder: (context, hovered, child) {
                        final bubbles = List.generate(
                          min(widget.contributors.length, gridPositions.length),
                          (index) => _BubbleData(
                            contributor: widget.contributors[index],
                            position: gridPositions[index],
                            index: index,
                          ),
                        );

                        // Z-order'a göre sırala: hover olan en sonda (en üstte)
                        bubbles.sort((a, b) {
                          if (hovered == a.index) return 1; // a en sonda
                          if (hovered == b.index) return -1; // b en sonda
                          return 0; // diğerleri aynı sırada
                        });

                        return Stack(
                          children: bubbles
                              .map((bubbleData) => _buildBubble(
                                    contributor: bubbleData.contributor,
                                    position: bubbleData.position,
                                    index: bubbleData.index,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Altıgen grid pozisyonlarını oluştur
  List<Offset> _generateHexGridPositions(
      Offset center, BoxConstraints constraints) {
    final positions = <Offset>[];

    // Merkez noktası
    positions.add(center);

    // Ring'ler halinde pozisyon ekle
    for (int ring = 1; ring <= widget.config.maxRings; ring++) {
      final ringRadius =
          widget.config.hexSpacing * ring * widget.config.ringSpacing;
      final itemsInRing = ring * 6; // Her ring'de 6*ring item

      for (int i = 0; i < itemsInRing; i++) {
        final angle = (i * 2 * pi / itemsInRing);
        final x = center.dx + cos(angle) * ringRadius;
        final y = center.dy + sin(angle) * ringRadius;

        // Ekran sınırları içinde mi kontrol et
        if (x > 0 &&
            x < constraints.maxWidth &&
            y > 0 &&
            y < constraints.maxHeight) {
          positions.add(Offset(x, y));
        }
      }
    }

    return positions;
  }

  Widget _buildBubble({
    required Contributor contributor,
    required Offset position,
    required int index,
  }) {
    return ValueListenableBuilder<Offset>(
      valueListenable: focusPoint,
      builder: (context, focus, child) {
        return ValueListenableBuilder<int?>(
          valueListenable: hoveredIndex,
          builder: (context, hovered, child) {
            double distance;
            double baseScale;

            if (hovered == index) {
              // AKTİF BUBBLE: Kendi merkezinden mouse'a mesafe
              distance = (focus - position).distance;

              // Merkeze yakınken büyük, uzaklaştıkça küçül (daha hassas kontrol)
              baseScale = 1.0 +
                  0.6 *
                      exp(-pow(
                          distance / widget.config.activeBubbleFalloff, 2));
            } else {
              // DİĞER BUBBLE'LAR: Mouse pozisyonundan kendi merkezlerine mesafe
              distance = (focus - position).distance;
              baseScale = 0.6 +
                  1.0 * exp(-pow(distance / widget.config.falloffRadius, 2));
            }

            final scale = hovered == index
                ? baseScale * widget.config.hoverScaleBoost
                : baseScale;

            // Blur hesaplama - hover durumunda blur'u kaldır
            final baseBlurSigma = ui.lerpDouble(
                    0.0,
                    widget.config.maxBlurSigma,
                    (distance / widget.config.maxBlurDistance)
                        .clamp(0.0, 1.0)) ??
                0.0;
            final blurSigma = hovered == index ? 0.0 : baseBlurSigma;

            // Z-order hesaplama - hover olan bubble her zaman en üstte
            double zIndex;
            if (hovered == index) {
              zIndex = 10000; // Hover olan bubble en üstte
            } else {
              zIndex = (1000 - distance); // Diğerleri mesafeye göre
            }

            return Positioned(
              left: position.dx - widget.config.baseBubbleSize / 2,
              top: position.dy - widget.config.baseBubbleSize / 2,
              child: RepaintBoundary(
                child: Transform.scale(
                  scale: scale.clamp(0.3, 2.0),
                  child: MouseRegion(
                    onEnter: (_) => hoveredIndex.value = index,
                    onExit: (_) => hoveredIndex.value = null,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigasyon işlemleri buraya
                      },
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: blurSigma,
                          sigmaY: blurSigma,
                        ),
                        child: _BubbleWidget(
                          contributor: contributor,
                          size: widget.config.baseBubbleSize,
                          isHovered: hovered == index,
                          zIndex: zIndex,
                          config: widget.config,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final Contributor contributor;
  final double size;
  final bool isHovered;
  final double zIndex;
  final HoneycombConfig config;

  const _BubbleWidget({
    required this.contributor,
    required this.size,
    required this.isHovered,
    required this.zIndex,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: config.animationDuration,
      curve: config.animationCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: Colors.blue.withAlpha((255 * 0.5).round()),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.3).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // Taşmaları görünür yap
        children: [
          // Ana bubble (fotoğraf/initials)
          ClipOval(
            child: _buildImageOrInitials(),
          ),

          // İsim - bubble ortasında
          Positioned(
            left: 15,
            right: 15,
            top: size * 0.70, // Bubble'ın ortasında
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: config.nameBackgroundColor
                    .withAlpha((255 * config.nameBackgroundOpacity).round()),
                borderRadius:
                    BorderRadius.circular(config.nameBackgroundRadius),
              ),
              child: Text(
                contributor.name.split(' ').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Role - arc şeklinde bubble'ın altında
          Positioned(
            left: -size * -0.2,
            right: -size * -0.2,
            bottom: -size * -0.35,
            child: SizedBox(
              height: size * 0.2,
              child: CustomPaint(
                painter: _ArcTextPainter(
                  text: contributor.role,
                  radius: size * -0.45,
                  fontSize: 8.5,
                  config: config,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrInitials() {
    final photoUrl = contributor.photoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildInitialsAvatar(),
        errorWidget: (context, url, error) => _buildInitialsAvatar(),
      );
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials(contributor.name);
    final backgroundColor = _getColorFromName(contributor.name);
    final textColor = _getContrastColor(backgroundColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Türkçe karakterleri doğru şekilde büyük harfe çevir
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String initials = '';

    for (int i = 0; i < parts.length && initials.length < 2; i++) {
      if (parts[i].isNotEmpty) {
        // Türkçe karakter dönüşümleri
        String firstChar = parts[i][0].toUpperCase();
        firstChar = firstChar
            .replaceAll('i', 'İ')
            .replaceAll('ı', 'I')
            .replaceAll('ç', 'Ç')
            .replaceAll('ş', 'Ş')
            .replaceAll('ğ', 'Ğ')
            .replaceAll('ü', 'Ü')
            .replaceAll('ö', 'Ö');
        initials += firstChar;
      }
    }

    return initials.isEmpty ? '?' : initials;
  }

  // İsimden renk üret (hash-based)
  Color _getColorFromName(String name) {
    final hash = name.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  // Kontrast renk hesapla
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

// Arc Text Painter - Role text'ini yay şeklinde çizmek için
class _ArcTextPainter extends CustomPainter {
  final String text;
  final double radius;
  final double fontSize;
  final HoneycombConfig config;

  _ArcTextPainter({
    required this.text,
    required this.radius,
    required this.fontSize,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final textStyle = TextStyle(
      color: Colors.white70,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );

    final centerX = size.width / 2;
    final centerY = radius > 0
        ? size.height * 0.3
        : size.height * 0.7; // Pozitif/negatif radius'a göre

    // Metni karakterlere böl
    final characters = text.split('');
    final totalChars = characters.length;

    // Yay açısını hesapla (toplam açı)
    final totalAngle = pi * 0.6; // 108 derece
    final anglePerChar = totalAngle / (totalChars - 1);
    final startAngle = -totalAngle / 2; // Ortadan başla

    final actualRadius = radius.abs();

    // Arka plan yayını çiz (eğer isteniyorsa)
    if (config.showArcBackground) {
      final backgroundPaint = Paint()
        ..color = config.arcBackgroundColor
            .withAlpha((255 * config.arcBackgroundOpacity).round())
        ..strokeWidth = fontSize * 1.25
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final backgroundPath = Path();
      final bgStartAngle = startAngle + (radius > 0 ? pi / 2 : -pi / 2);
      final bgSweepAngle = totalAngle;

      backgroundPath.arcTo(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: actualRadius,
        ),
        bgStartAngle,
        bgSweepAngle,
        false,
      );

      canvas.drawPath(backgroundPath, backgroundPaint);
    }

    for (int i = 0; i < characters.length; i++) {
      final char = characters[i];
      final angle = startAngle + (i * anglePerChar);

      // Karakterin pozisyonunu hesapla
      final adjustedAngle = radius > 0 ? angle + pi / 2 : angle - pi / 2;
      final x = centerX + cos(adjustedAngle) * actualRadius;
      final y = centerY + sin(adjustedAngle) * actualRadius;

      // TextPainter oluştur
      final textSpan = TextSpan(text: char, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Canvas'ı döndür ve metni çiz
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ArcTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.radius != radius ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.config != config;
  }
}
