import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'article_screen.dart';
import '../widgets/tappable.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<dynamic> _bookmarks = [];
  List<String> _favoriteSources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadFavoriteSources();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarks = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoriteSources() async {
    try {
      final sources = await ApiService.getFavoriteSources();
      if (mounted) setState(() => _favoriteSources = sources);
    } catch (e) {
      // Silencieux
    }
  }

  Future<void> _removeBookmark(String articleId) async {
    try {
      await ApiService.removeBookmark(articleId);
      await HapticFeedback.lightImpact();
      if (mounted) {
        setState(() {
          _bookmarks.removeWhere((a) => a['id'] == articleId);
        });
      }
    } catch (e) {
      // Silencieux
    }
  }

  Future<void> _toggleFavoriteSource(String? sourceName) async {
    if (sourceName == null) return;
    try {
      if (_favoriteSources.contains(sourceName)) {
        await ApiService.removeFavoriteSource(sourceName);
      } else {
        await ApiService.addFavoriteSource(sourceName);
      }
      await HapticFeedback.lightImpact();
      _loadFavoriteSources();
    } catch (e) {
      // Silencieux
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Text(
                    'Favoris',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary(context),
                          ),
                        )
                      : _bookmarks.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadBookmarks,
                          color: AppColors.textPrimary(context),
                          backgroundColor: AppColors.background(context),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _bookmarks.length,
                            itemBuilder: (context, index) {
                              final article = _bookmarks[index];
                              final category = article['category'];
                              final color = _categoryColor(category);
                              final sourceName = article['source_name'];
                              final isFav = _favoriteSources.contains(
                                sourceName,
                              );

                              return Tappable(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ArticleScreen(article: article),
                                    ),
                                  ).then((_) => _loadBookmarks());
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.35 : 0.12,
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.12),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 20,
                                        sigmaY: 20,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.glassFill(context),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: AppColors.glassBorder(
                                              context,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Source + catégorie + suppression
                                              Row(
                                                children: [
                                                  Tappable(
                                                    onTap: () =>
                                                        _toggleFavoriteSource(
                                                          sourceName,
                                                        ),
                                                    scale: 0.94,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(
                                                          alpha: isDark
                                                              ? 0.3
                                                              : 0.18,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        border: Border.all(
                                                          color: color
                                                              .withValues(
                                                                alpha: isDark
                                                                    ? 0.6
                                                                    : 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isFav
                                                                ? Icons
                                                                      .star_rounded
                                                                : Icons
                                                                      .star_outline_rounded,
                                                            color: isFav
                                                                ? Colors.amber
                                                                : AppColors.textTertiary(
                                                                    context,
                                                                  ),
                                                            size: 13,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            sourceName ?? '',
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? color.withValues(
                                                                      alpha:
                                                                          0.95,
                                                                    )
                                                                  : color,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  Text(
                                                    '${_categoryEmoji(category)} ${category ?? ''}',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textSecondary(
                                                            context,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                                  ),

                                                  const Spacer(),

                                                  Tappable(
                                                    onTap: () =>
                                                        _removeBookmark(
                                                          article['id'],
                                                        ),
                                                    scale: 0.9,
                                                    child: Icon(
                                                      Icons
                                                          .bookmark_remove_rounded,
                                                      color:
                                                          AppColors.textTertiary(
                                                            context,
                                                          ),
                                                      size: 20,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 10),

                                              Text(
                                                article['title'] ?? '',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary(
                                                    context,
                                                  ),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.4,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              const SizedBox(height: 10),

                                              // Date + temps de lecture
                                              Row(
                                                children: [
                                                  Text(
                                                    _formatDate(
                                                      article['published_at'],
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textTertiary(
                                                            context,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (article['reading_time'] !=
                                                      null) ...[
                                                    Text(
                                                      '  ·  ',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textTertiary(
                                                              context,
                                                            ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${article['reading_time']} min',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textTertiary(
                                                              context,
                                                            ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline_rounded,
            color: AppColors.textTertiary(context),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun favori pour l\'instant',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute des articles depuis le feed',
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 14,
            ),
          ),
        ],
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
