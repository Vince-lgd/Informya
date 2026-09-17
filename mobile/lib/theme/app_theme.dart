import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Couleurs adaptées au thème courant — un seul point de vérité
class AppColors {
  static Color background(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF18241D) : const Color(0xFF99B4A0);
  }

  static Color circle1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2E4536) : const Color(0xFFB8CDB8);
  }

  static Color circle2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF10190F) : const Color(0xFF7A9E8A);
  }

  static Color circle3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF253A2A) : const Color(0xFFA8C4A8);
  }

  // ── Couleurs de texte adaptatives ────────────────────────

  /// Texte principal — titres, contenu important
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF1A2E20);
  }

  /// Texte secondaire — sous-titres, métadonnées
  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF1A2E20).withValues(alpha: 0.65);
  }

  /// Texte tertiaire — labels de section, placeholders
  static Color textTertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF1A2E20).withValues(alpha: 0.45);
  }

  /// Icônes
  static Color icon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF1A2E20).withValues(alpha: 0.7);
  }

  /// Fond des cartes glass
  static Color glassFill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.45);
  }

  /// Bordure des cartes glass
  static Color glassBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.7);
  }
}

// Gère le thème choisi par l'utilisateur (clair / sombre / auto) et le persiste
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadTheme();
  }

  // Charge le thème sauvegardé au démarrage de l'app
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // Change le thème et le sauvegarde
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await prefs.setString('theme_mode', value);
  }
}

// Instance unique partagée dans toute l'app
final themeController = ThemeController();
