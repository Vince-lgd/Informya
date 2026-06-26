import 'dart:ui';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'article_screen.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

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
  String? _selectedContentType;
  int? _selectedMaxReadingTime;
  String? _selectedSourceBias;

  List<String> _favoriteSources = [];

  @override
  void initState() {
    super.initState();

    _isLoading = false;
    _loadFeed(refresh: true);
    _loadFavoriteSources();
  }

  Future<void> _loadFavoriteSources() async {
    try {
      final sources = await ApiService.getFavoriteSources();
      if (mounted) setState(() => _favoriteSources = sources);
    } catch (e) {
      // Silencieux
    }
  }

  final List<String> _categories = [
    'Tout',
    'Politique',
    'Sport',
    'Bourse',
    'Tech',
    'Art',
    'Science',
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
        contentType: _selectedContentType,
        maxReadingTime: _selectedMaxReadingTime,
        sourceBias: _selectedSourceBias,
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF99B4A0).withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtres',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedContentType = null;
                                _selectedMaxReadingTime = null;
                                _selectedSourceBias = null;
                              });
                              _loadFeed(refresh: true);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Type d\'article',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _filterChip(
                            'Tout',
                            null,
                            _selectedContentType,
                            (v) =>
                                setModalState(() => _selectedContentType = v),
                          ),
                          _filterChip(
                            'Brève',
                            'brève',
                            _selectedContentType,
                            (v) =>
                                setModalState(() => _selectedContentType = v),
                          ),
                          _filterChip(
                            'Article',
                            'article',
                            _selectedContentType,
                            (v) =>
                                setModalState(() => _selectedContentType = v),
                          ),
                          _filterChip(
                            'Analyse',
                            'analyse',
                            _selectedContentType,
                            (v) =>
                                setModalState(() => _selectedContentType = v),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Temps de lecture',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _filterChipInt(
                            'Tout',
                            null,
                            _selectedMaxReadingTime,
                            (v) => setModalState(
                              () => _selectedMaxReadingTime = v,
                            ),
                          ),
                          _filterChipInt(
                            '< 1 min',
                            1,
                            _selectedMaxReadingTime,
                            (v) => setModalState(
                              () => _selectedMaxReadingTime = v,
                            ),
                          ),
                          _filterChipInt(
                            '< 3 min',
                            3,
                            _selectedMaxReadingTime,
                            (v) => setModalState(
                              () => _selectedMaxReadingTime = v,
                            ),
                          ),
                          _filterChipInt(
                            '< 5 min',
                            5,
                            _selectedMaxReadingTime,
                            (v) => setModalState(
                              () => _selectedMaxReadingTime = v,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Biais de la source',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _filterChip(
                            'Tout',
                            null,
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                          _filterChip(
                            'Gauche',
                            'left',
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                          _filterChip(
                            'Centre-G',
                            'center-left',
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                          _filterChip(
                            'Centre',
                            'center',
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                          _filterChip(
                            'Centre-D',
                            'center-right',
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                          _filterChip(
                            'Droite',
                            'right',
                            _selectedSourceBias,
                            (v) => setModalState(() => _selectedSourceBias = v),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      GestureDetector(
                        onTap: () {
                          setState(() {});
                          _loadFeed(refresh: true);
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Appliquer les filtres',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(
    String label,
    String? value,
    String? selected,
    Function(String?) onTap,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.6 : 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 1 : 0.7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _filterChipInt(
    String label,
    int? value,
    int? selected,
    Function(int?) onTap,
  ) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.6 : 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 1 : 0.7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Informya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilters,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    (_selectedContentType != null ||
                                        _selectedMaxReadingTime != null ||
                                        _selectedSourceBias != null)
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isSelected ? 0.6 : 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: isSelected ? 1 : 0.7,
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
                                  isFavoriteSource: _favoriteSources.contains(
                                    _articles[index]['source_name'],
                                  ),
                                  onFavoriteToggled: _loadFavoriteSources,
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
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isFavoriteSource;
  final VoidCallback? onFavoriteToggled;

  const _ArticleCard({
    required this.article,
    this.isFavoriteSource = false,
    this.onFavoriteToggled,
  });

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
    final category = article['category'];
    final color = _categoryColor(category);

    return Container(
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
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
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
                              // Badge source
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final sourceName =
                                            article['source_name'];
                                        if (sourceName == null) return;
                                        if (isFavoriteSource) {
                                          await ApiService.removeFavoriteSource(
                                            sourceName,
                                          );
                                        } else {
                                          await ApiService.addFavoriteSource(
                                            sourceName,
                                          );
                                        }
                                        await HapticFeedback.lightImpact();
                                        // Recharge les favoris dans le feed
                                        onFavoriteToggled?.call();
                                      },
                                      child: Icon(
                                        isFavoriteSource
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: isFavoriteSource
                                            ? Colors.amber
                                            : Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                        size: 18,
                                      ),
                                    ),
                                    Text(
                                      article['source_name'] ?? '',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_categoryEmoji(category)} $category',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
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
                                  color: Colors.white.withValues(alpha: 0.8),
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
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _biasLabel(article['source_bias']),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
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
    );
  }
}
