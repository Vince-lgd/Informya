import 'dart:ui';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tappable.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  List<String> _favoriteSources = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userResult = await ApiService.getMe();
      final sourcesResult = await ApiService.getFavoriteSources();

      if (mounted) {
        setState(() {
          _user = userResult;
          _favoriteSources = sourcesResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// SnackBar cohérente avec le thème courant
  void _showSnack(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : const Color(0xFF1A2E20);
    final contentColor = isDark ? const Color(0xFF1A2E20) : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: contentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: contentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyInviteCode() {
    final code = _user?['invite_code'];
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    _showSnack('Code copié !');
  }

  Future<void> _logout() async {
    await HapticFeedback.mediumImpact();
    await ApiService.clearToken();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  String _readingStyleLabel(String? style) {
    switch (style) {
      case 'bullet':
        return 'Points clés';
      case 'journalistic':
        return 'Journalistique';
      case 'simple':
        return 'Vulgarisé';
      default:
        return 'Points clés';
    }
  }

  String _formatJoinDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'janv.',
        'févr.',
        'mars',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sept.',
        'oct.',
        'nov.',
        'déc.',
      ];
      return 'Membre depuis ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Sélecteur de style de lecture ────────────────────────

  void _showReadingStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background(context).withValues(alpha: 0.97),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: AppColors.glassBorder(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Style de lecture',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choisissez le style de lecture pour vos résumés d\'articles',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _styleOption(
                    'bullet',
                    'Points clés',
                    'Résumé par listes à puces',
                  ),
                  const SizedBox(height: 10),
                  _styleOption(
                    'journalistic',
                    'Journalistique',
                    'Ton article classique',
                  ),
                  const SizedBox(height: 10),
                  _styleOption(
                    'simple',
                    'Vulgarisé',
                    'Explications simplifiées',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _styleOption(String value, String title, String subtitle) {
    final isSelected = _user?['reading_style'] == value;

    return Tappable(
      onTap: () async {
        Navigator.pop(context);
        try {
          final result = await ApiService.updateReadingStyle(value);
          await HapticFeedback.lightImpact();
          if (mounted) {
            setState(() => _user = result);
            _showSnack('Style de lecture mis à jour');
          }
        } catch (e) {
          // Erreur silencieuse
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.glassFill(context)
              : AppColors.glassFill(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.glassBorder(context)
                : AppColors.glassBorder(context).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.textPrimary(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Sélecteur de thème ───────────────────────────────────

  Widget _themeOption({
    required IconData icon,
    required String label,
    required ThemeMode mode,
  }) {
    final isSelected = themeController.themeMode == mode;

    return Tappable(
      onTap: () => themeController.setThemeMode(mode),
      child: Row(
        children: [
          Icon(icon, color: AppColors.icon(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.textPrimary(context),
              size: 20,
            ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _blurCircle(200, AppColors.circle1(context)),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _blurCircle(180, AppColors.circle2(context)),
          ),

          SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary(context),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil',
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Carte identité
                        _glassCard(
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.glassFill(context),
                                  border: Border.all(
                                    color: AppColors.glassBorder(context),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    (_user?['username'] ?? '?')
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user?['username'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.textPrimary(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _user?['email'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatJoinDate(_user?['created_at']),
                                      style: TextStyle(
                                        color: AppColors.textTertiary(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Style de lecture
                        _sectionLabel(
                          'Style de lecture des résumés d\'articles',
                        ),
                        const SizedBox(height: 8),
                        Tappable(
                          onTap: _showReadingStylePicker,
                          child: _glassCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.icon(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _readingStyleLabel(_user?['reading_style']),
                                    style: TextStyle(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textTertiary(context),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Apparence
                        _sectionLabel('Apparence'),
                        const SizedBox(height: 8),
                        ListenableBuilder(
                          listenable: themeController,
                          builder: (context, _) {
                            return _glassCard(
                              child: Column(
                                children: [
                                  _themeOption(
                                    icon: Icons.light_mode_rounded,
                                    label: 'Clair',
                                    mode: ThemeMode.light,
                                  ),
                                  Divider(
                                    color: AppColors.glassBorder(context),
                                    height: 20,
                                  ),
                                  _themeOption(
                                    icon: Icons.dark_mode_rounded,
                                    label: 'Sombre',
                                    mode: ThemeMode.dark,
                                  ),
                                  Divider(
                                    color: AppColors.glassBorder(context),
                                    height: 20,
                                  ),
                                  _themeOption(
                                    icon: Icons.brightness_auto_rounded,
                                    label: 'Automatique',
                                    mode: ThemeMode.system,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Sources favorites
                        _sectionLabel('Mes sources favorites'),
                        const SizedBox(height: 8),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_favoriteSources.isEmpty)
                                Text(
                                  'Aucune source favorite — appuie sur ⭐ dans le feed',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 13,
                                  ),
                                )
                              else
                                ..._favoriteSources.map(
                                  (source) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            source,
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                context,
                                              ),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Tappable(
                                          onTap: () async {
                                            await ApiService.removeFavoriteSource(
                                              source,
                                            );
                                            await HapticFeedback.lightImpact();
                                            _loadProfile();
                                          },
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: AppColors.textTertiary(
                                              context,
                                            ),
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Code d'invitation
                        _sectionLabel('Inviter famille & amis'),
                        const SizedBox(height: 8),
                        Tappable(
                          onTap: _copyInviteCode,
                          child: _glassCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  color: AppColors.icon(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Code d\'invitation',
                                        style: TextStyle(
                                          color: AppColors.textSecondary(
                                            context,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _user?['invite_code'] ?? '',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.textTertiary(context),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Déconnexion
                        Tappable(
                          onTap: _logout,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFB3261E),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Se déconnecter',
                                      style: TextStyle(
                                        color: Color(0xFFB3261E),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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
                  ),
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ───────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassFill(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.glassBorder(context),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
