import 'dart:ui';
import '../services/api_service.dart';
import 'article_screen.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<dynamic> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getBookmarks();
      setState(() {
        _bookmarks = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBookmark(String articleId) async {
    try {
      await ApiService.removeBookmark(articleId);
      setState(() {
        _bookmarks.removeWhere((a) => a['id'] == articleId);
      });
    } catch (e) {
      // Erreur silencieuse
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
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -60,
            right: -60,
            child: _blurCircle(200, const Color(0xFFB8CDB8)),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _blurCircle(180, const Color(0xFF7A9E8A)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Text(
                    'Favoris',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Liste
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _bookmarks.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadBookmarks,
                          color: Colors.white,
                          backgroundColor: const Color(0xFF99B4A0),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _bookmarks.length,
                            itemBuilder: (context, index) {
                              final article = _bookmarks[index];
                              final category = article['category'];
                              final color = _categoryColor(article['category']);

                              return GestureDetector(
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
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 15,
                                        sigmaY: 15,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              // Contenu
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: color
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              border: Border.all(
                                                                color: color
                                                                    .withValues(
                                                                      alpha:
                                                                          0.4,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              article['source_name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                color: color,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            '${_categoryEmoji(category)} $category',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          // Bouton supprimer
                                                          GestureDetector(
                                                            onTap: () async {
                                                              final articleId =
                                                                  article['id'];

                                                              HapticFeedback.selectionClick();

                                                              try {
                                                                await _removeBookmark(
                                                                  articleId,
                                                                );

                                                                if (!mounted)
                                                                  return;

                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: const Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .bookmark_remove_rounded,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              18,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                        Text(
                                                                          'Retiré des favoris',
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    backgroundColor: Colors
                                                                        .black
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                );
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              1,
                                                                        ),
                                                                    backgroundColor: Colors
                                                                        .red
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                    content: const Text(
                                                                      "Erreur lors de la suppression",
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: Icon(
                                                              Icons
                                                                  .bookmark_remove_rounded,
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                              size: 25,
                                                            ),
                                                          ),
                                                        ],
                                                      ),

                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                      Text(
                                                        article['title'] ?? '',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          height: 1.4,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),

                                                      const SizedBox(
                                                        height: 10,
                                                      ),

                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            _formatDate(
                                                              article['published_at'],
                                                            ),
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          if (article['source_bias'] !=
                                                              null)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 3,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                _biasLabel(
                                                                  article['source_bias'],
                                                                ),
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
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
            color: Colors.white.withValues(alpha: 0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun favori pour l\'instant',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute des articles depuis le feed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
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
