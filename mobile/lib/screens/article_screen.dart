import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tappable.dart';

class ArticleScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool _isBookmarked = false;
  bool _isFavoriteSource = false;
  bool _isLoading = false;

  String? _aiSummary;
  bool _isSummaryLoading = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
    _checkIfFavoriteSource();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final bookmarks = await ApiService.getBookmarks();
      final articleId = widget.article['id'];
      if (mounted) {
        setState(() {
          _isBookmarked = bookmarks.any((b) => b['id'] == articleId);
        });
      }
    } catch (e) {
      // Silencieux
    }
  }

  Future<void> _checkIfFavoriteSource() async {
    try {
      final sources = await ApiService.getFavoriteSources();
      final sourceName = widget.article['source_name'];
      if (mounted) {
        setState(() => _isFavoriteSource = sources.contains(sourceName));
      }
    } catch (e) {
      // Silencieux
    }
  }

  /// SnackBar cohérente avec le thème courant
  void _showSnack(String message, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : const Color(0xFF1A2E20);
    final contentColor = isDark ? const Color(0xFF1A2E20) : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: contentColor, size: 18),
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

  Future<void> _toggleBookmark() async {
    setState(() => _isLoading = true);
    try {
      if (_isBookmarked) {
        await ApiService.removeBookmark(widget.article['id']);
        await HapticFeedback.lightImpact();
        if (mounted) {
          _showSnack('Retiré des favoris', Icons.bookmark_remove_rounded);
        }
      } else {
        await ApiService.addBookmark(widget.article['id']);
        await HapticFeedback.mediumImpact();
        if (mounted) {
          _showSnack('Ajouté aux favoris !', Icons.bookmark_rounded);
        }
      }
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
    } catch (e) {
      // Silencieux
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavoriteSource() async {
    final sourceName = widget.article['source_name'];
    if (sourceName == null) return;
    try {
      if (_isFavoriteSource) {
        await ApiService.removeFavoriteSource(sourceName);
      } else {
        await ApiService.addFavoriteSource(sourceName);
      }
      await HapticFeedback.lightImpact();
      if (mounted) setState(() => _isFavoriteSource = !_isFavoriteSource);
    } catch (e) {
      // Silencieux
    }
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });
    try {
      final result = await ApiService.getArticleSummary(widget.article['id']);
      if (mounted) setState(() => _aiSummary = result['summary']);
    } catch (e) {
      if (mounted) {
        setState(() => _summaryError = 'Résumé indisponible pour le moment');
      }
    } finally {
      if (mounted) setState(() => _isSummaryLoading = false);
    }
  }

  Future<void> _openUrl() async {
    final url = widget.article['url'];
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'politique':
        return const Color(0xFF0288D1);
      case 'sport':
        return const Color(0xFF27AE60);
      case 'bourse':
        return const Color(0xFFF39C12);
      case 'tech':
        return const Color(0xFF8E44AD);
      case 'art':
        return const Color(0xFFE91E8C);
      case 'science':
        return const Color(0xFF8D6E63);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _categoryEmoji(String? category) {
    switch (category) {
      case 'politique':
        return '🏛️';
      case 'sport':
        return '⚽';
      case 'bourse':
        return '📈';
      case 'tech':
        return '💻';
      case 'art':
        return '🎨';
      case 'science':
        return '🔬';
      default:
        return '📰';
    }
  }

  String _biasLabel(String? bias) {
    switch (bias) {
      case 'left':
        return 'Gauche';
      case 'center-left':
        return 'Centre-G';
      case 'center':
        return 'Centre';
      case 'center-right':
        return 'Centre-D';
      case 'right':
        return 'Droite';
      default:
        return '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final category = article['category'];
    final color = _categoryColor(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Tappable(
                        onTap: () => Navigator.pop(context),
                        child: _glassButton(
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.icon(context),
                            size: 20,
                          ),
                        ),
                      ),
                      Tappable(
                        onTap: _isLoading ? null : _toggleBookmark,
                        child: _glassButton(
                          highlighted: _isBookmarked,
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: AppColors.icon(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source + catégorie
                        Row(
                          children: [
                            Tappable(
                              onTap: _toggleFavoriteSource,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                    alpha: isDark ? 0.3 : 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color.withValues(
                                      alpha: isDark ? 0.6 : 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isFavoriteSource
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: _isFavoriteSource
                                          ? Colors.amber
                                          : AppColors.textTertiary(context),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      article['source_name'] ?? '',
                                      style: TextStyle(
                                        color: isDark
                                            ? color.withValues(alpha: 0.95)
                                            : color,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_categoryEmoji(category)} $category',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Date + temps de lecture + biais
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatDate(article['published_at']),
                                  style: TextStyle(
                                    color: AppColors.textTertiary(context),
                                    fontSize: 13,
                                  ),
                                ),
                                if (article['reading_time'] != null) ...[
                                  Text(
                                    '  ·  ',
                                    style: TextStyle(
                                      color: AppColors.textTertiary(context),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${article['reading_time']} min de lecture',
                                    style: TextStyle(
                                      color: AppColors.textTertiary(context),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (article['source_bias'] != null &&
                                _biasLabel(article['source_bias']).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _biasLabel(article['source_bias']),
                                  style: TextStyle(
                                    color: AppColors.textTertiary(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Titre
                        Text(
                          article['title'] ?? '',
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Résumé IA
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.glassFill(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.glassBorder(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: AppColors.icon(context),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Résumé IA',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_aiSummary != null)
                                    Text(
                                      _aiSummary!,
                                      style: TextStyle(
                                        color: AppColors.textPrimary(context),
                                        fontSize: 14,
                                        height: 1.6,
                                      ),
                                    )
                                  else if (_isSummaryLoading)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.textPrimary(context),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  else
                                    Tappable(
                                      onTap: _generateSummary,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.glassFill(
                                            context,
                                          ).withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.glassBorder(
                                              context,
                                            ).withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _summaryError != null
                                                  ? Icons.error_outline_rounded
                                                  : Icons.touch_app_rounded,
                                              color: AppColors.textSecondary(
                                                context,
                                              ),
                                              size: 15,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _summaryError ??
                                                  'Générer un résumé',
                                              style: TextStyle(
                                                color: AppColors.textSecondary(
                                                  context,
                                                ),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lire l'article complet
                        Tappable(
                          onTap: _openUrl,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.glassFill(context),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.glassBorder(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      color: AppColors.textPrimary(context),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lire l\'article complet',
                                      style: TextStyle(
                                        color: AppColors.textPrimary(context),
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

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child, bool highlighted = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.glassFill(context)
                : AppColors.glassFill(context).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder(context)),
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
