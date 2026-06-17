import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'article_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedCategory;

  @override
void initState() {
  super.initState();

  _isLoading = false;
  _loadFeed(refresh: true);
}

  final List<String> _categories = [
    'Tout', 'Politique', 'Sport', 'Bourse', 'Tech', 'Art', 'Science'
  ];

Future<void> _loadFeed({bool refresh = false}) async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;

    if (refresh) {
      _currentPage = 1;
      _articles = [];
      _hasMore = true;
    }
  });

  try {
    final result = await ApiService.getFeed(
      page: _currentPage,
      category: _selectedCategory == 'Tout'
          ? null
          : _selectedCategory?.toLowerCase(),
    );

    final List<dynamic> newArticles = result['articles'] ?? [];

    setState(() {
      if (refresh) {
        _articles = newArticles;
      } else {
        _articles.addAll(newArticles);
      }

      _hasMore = result['has_more'] ?? false;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF99B4A0),
      body: Stack(
        children: [
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: const Text(
                    'Informya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = (_selectedCategory ?? 'Tout') == cat;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _loadFeed(refresh: true);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.35)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                isSelected ? 0.6 : 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: Colors.white.withOpacity(
                                isSelected ? 1 : 0.7,
                              ),
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading && _articles.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadFeed(refresh: true),
                          color: Colors.white,
                          backgroundColor: const Color(0xFF99B4A0),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _articles.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _articles.length) {
                                if (_hasMore && !_isLoading) {
                                Future.microtask(() {
                                  if (mounted) {
                                    _currentPage++;
                                    _loadFeed();
                                  }
                                });
                              }
                                return _isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArticleScreen(
                                        article: _articles[index],
                                      ),
                                    ),
                                  );
                                },
                                child: _ArticleCard(
                                  article: _articles[index],
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

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;

  const _ArticleCard({required this.article});

  Color _categoryColor(String? category) {
    switch (category) {
      case 'politique': return const Color(0xFF0288D1);
      case 'sport':     return const Color(0xFF27AE60);
      case 'bourse':    return const Color(0xFFF39C12);
      case 'tech':      return const Color(0xFF8E44AD);
      case 'art':       return const Color(0xFFE91E8C);
      case 'science':   return const Color(0xFF8D6E63);
      default:          return const Color(0xFF95A5A6);
    }
  }

  String _categoryEmoji(String? category) {
    switch (category) {
      case 'politique': return '🏛️';
      case 'sport':     return '⚽';
      case 'bourse':    return '📈';
      case 'tech':      return '💻';
      case 'art':       return '🎨';
      case 'science':   return '🔬';
      default:          return '📰';
    }
  }

  String _biasLabel(String? bias) {
    switch (bias) {
      case 'left':         return 'Gauche';
      case 'center-left':  return 'Centre-G';
      case 'center':       return 'Centre';
      case 'center-right': return 'Centre-D';
      case 'right':        return 'Droite';
      default:             return '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = article['category'];
    final color = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
               children: [
                  // Contenu
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Source + catégorie
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  article['source_name'] ?? '',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_categoryEmoji(category)} $category',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Titre
                          Text(
                            article['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 10),

                          // Date + biais
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(article['published_at']),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              if (article['source_bias'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _biasLabel(article['source_bias']),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
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
    );
  }
}