import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'article_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/tappable.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedCategory;
  String? _selectedContentType;
  int? _selectedMaxReadingTime;
  String? _selectedSourceBias;

  List<String> _favoriteSources = [];

  final List<String> _categories = [
    'Tout',
    '⭐ Mes sources',
    'Politique',
    'Sport',
    'Bourse',
    'Tech',
    'Art',
    'Science',
  ];

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

  Future<void> _loadFeed({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _articles = [];
        _hasMore = true;
        _hasError = false;
      }
    });

    try {
      final result = await ApiService.getFeed(
        page: _currentPage,
        category:
            (_selectedCategory == 'Tout' ||
                _selectedCategory == '⭐ Mes sources' ||
                _selectedCategory == null)
            ? null
            : _selectedCategory?.toLowerCase(),
        favoritesOnly: _selectedCategory == '⭐ Mes sources',
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
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _shareArticle(Map<String, dynamic> article) async {
    final url = article['url'] ?? '';
    if (url.isEmpty) return;

    await HapticFeedback.mediumImpact();

    final text =
        '${article['title']}\n\n${article['source_name']}\n$url\n\nPartagé via Informya';

    await SharePlus.instance.share(
      ShareParams(text: text, subject: article['title']),
    );
  }

  // ── Styles partagés des chips ────────────────────────────

  /// Point coloré associé à une catégorie. null = pas de point.
  Color? _categoryDotColor(String cat) {
    switch (cat) {
      case 'Politique':
        return const Color(0xFF0288D1);
      case 'Sport':
        return const Color(0xFF27AE60);
      case 'Bourse':
        return const Color(0xFFF39C12);
      case 'Tech':
        return const Color(0xFF8E44AD);
      case 'Art':
        return const Color(0xFFE91E8C);
      case 'Science':
        return const Color(0xFF8D6E63);
      default:
        return null;
    }
  }

  BoxDecoration _chipDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected
          ? AppColors.glassFill(context)
          : AppColors.glassFill(context).withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected
            ? AppColors.glassBorder(context)
            : AppColors.glassBorder(context).withValues(alpha: 0.6),
      ),
    );
  }

  TextStyle _chipTextStyle(bool isSelected) {
    return TextStyle(
      color: AppColors.textPrimary(
        context,
      ).withValues(alpha: isSelected ? 1.0 : 0.72),
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );
  }

  Widget _filterLabel(String text, BuildContext ctx) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary(ctx),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _filterChip(
    String label,
    String? value,
    String? selected,
    Function(String?) onTap,
  ) {
    final isSelected = selected == value;
    return Tappable(
      onTap: () => onTap(value),
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: _chipDecoration(isSelected),
        child: Text(label, style: _chipTextStyle(isSelected)),
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
    return Tappable(
      onTap: () => onTap(value),
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: _chipDecoration(isSelected),
        child: Text(label, style: _chipTextStyle(isSelected)),
      ),
    );
  }

  /// État affiché quand le serveur est injoignable
  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textTertiary(context),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion impossible',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie ta connexion internet et réessaie',
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Tappable(
              onTap: () => _loadFeed(refresh: true),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textPrimary(context),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Réessayer',
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
          ],
        ),
      ),
    );
  }

  /// État affiché quand la requête a réussi mais ne renvoie rien
  Widget _emptyState() {
    final isFavoritesTab = _selectedCategory == '⭐ Mes sources';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFavoritesTab
                  ? Icons.star_outline_rounded
                  : Icons.newspaper_outlined,
              color: AppColors.textTertiary(context),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isFavoritesTab
                  ? 'Aucune source favorite'
                  : 'Aucun article disponible',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFavoritesTab
                  ? 'Ajoute des sources via l\'étoile ⭐ sur les cartes'
                  : 'Essaie un autre filtre ou reviens plus tard',
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  // ── Bottom sheet filtres ─────────────────────────────────

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background(
                      sheetContext,
                    ).withValues(alpha: 0.97),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: AppColors.glassBorder(sheetContext),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtres',
                            style: TextStyle(
                              color: AppColors.textPrimary(sheetContext),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Tappable(
                            onTap: () {
                              setState(() {
                                _selectedContentType = null;
                                _selectedMaxReadingTime = null;
                                _selectedSourceBias = null;
                              });
                              _loadFeed(refresh: true);
                              Navigator.pop(sheetContext);
                            },
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                color: AppColors.textSecondary(sheetContext),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _filterLabel('Type d\'article', sheetContext),
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

                      _filterLabel('Temps de lecture', sheetContext),
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

                      _filterLabel('Biais de la source', sheetContext),
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

                      Tappable(
                        onTap: () {
                          setState(() {});
                          _loadFeed(refresh: true);
                          Navigator.pop(sheetContext);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.glassFill(sheetContext),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.glassBorder(sheetContext),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Appliquer les filtres',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(sheetContext),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informya',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Tappable(
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
                                    ? AppColors.glassFill(context)
                                    : AppColors.glassFill(
                                        context,
                                      ).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.glassBorder(context),
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: AppColors.icon(context),
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

                // Chips catégories avec point coloré
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = (_selectedCategory ?? 'Tout') == cat;
                      final dotColor = _categoryDotColor(cat);

                      return Tappable(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _loadFeed(refresh: true);
                        },
                        scale: 0.94,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: _chipDecoration(isSelected),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dotColor != null) ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dotColor.withValues(
                                      alpha: isSelected ? 1.0 : 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                              Text(cat, style: _chipTextStyle(isSelected)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Liste
                Expanded(
                  child: _isLoading && _articles.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary(context),
                          ),
                        )
                      : _hasError && _articles.isEmpty
                      ? _errorState()
                      : !_isLoading && _articles.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: () => _loadFeed(refresh: true),
                          color: AppColors.textPrimary(context),
                          backgroundColor: AppColors.background(context),
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
                                    ? Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onLongPress: () =>
                                    _shareArticle(_articles[index]),
                                child: Tappable(
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

// ── Carte article ──────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassFill(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.glassBorder(context),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + catégorie
                  Row(
                    children: [
                      Tappable(
                        onTap: () async {
                          final sourceName = article['source_name'];
                          if (sourceName == null) return;
                          if (isFavoriteSource) {
                            await ApiService.removeFavoriteSource(sourceName);
                          } else {
                            await ApiService.addFavoriteSource(sourceName);
                          }
                          await HapticFeedback.lightImpact();
                          onFavoriteToggled?.call();
                        },
                        scale: 0.94,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.3 : 0.18),
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
                                isFavoriteSource
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isFavoriteSource
                                    ? Colors.amber
                                    : AppColors.textTertiary(context),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                article['source_name'] ?? '',
                                style: TextStyle(
                                  color: isDark
                                      ? color.withValues(alpha: 0.95)
                                      : color,
                                  fontSize: 12,
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
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Titre
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
                              fontSize: 12,
                            ),
                          ),
                          if (article['reading_time'] != null) ...[
                            Text(
                              '  ·  ',
                              style: TextStyle(
                                color: AppColors.textTertiary(context),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${article['reading_time']} min',
                              style: TextStyle(
                                color: AppColors.textTertiary(context),
                                fontSize: 12,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
