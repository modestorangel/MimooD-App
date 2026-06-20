import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'services/wordpress_service.dart';
import 'models/post_model.dart';
import 'models/category_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => BookmarksProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Theme Provider
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Bookmarks Provider
class BookmarksProvider with ChangeNotifier {
  List<String> _bookmarkedIds = [];
  bool _isInitialized = false;

  List<String> get bookmarkedIds => _bookmarkedIds;
  bool get isInitialized => _isInitialized;

  BookmarksProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedIds = prefs.getStringList('bookmarks') ?? [];
    _isInitialized = true;
    notifyListeners();
  }

  bool isBookmarked(String id) {
    return _bookmarkedIds.contains(id);
  }

  Future<void> toggleBookmark(String id) async {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarkedIds);
    notifyListeners();
  }
}

// Router configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MainNavigationScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'details/:id',
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return DetailScreen(postId: id);
          },
        ),
        GoRoute(
          path: 'search',
          builder: (BuildContext context, GoRouterState state) {
            return const SearchScreen();
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Beautiful deep pink/rose accent typical of MimooD's branding
    const Color primarySeedColor = Color(0xFFD63384);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'MimooD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor,
          brightness: Brightness.light,
          primary: primarySeedColor,
          surface: const Color(0xFFFAFAFA),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: const Color(0xFFFAFAFA),
          foregroundColor: Colors.black,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor,
          brightness: Brightness.dark,
          primary: primarySeedColor,
          surface: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: const Color(0xFF121212),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}

// Main Navigation Screen with Bottom Tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper),
              label: 'Notícias',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Salvos',
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen with Dynamic Categories TabBar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WordpressService _wordpressService = WordpressService();
  List<WordPressCategory> _categories = [];
  bool _isLoadingCategories = true;
  String _categoriesError = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _wordpressService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categoriesError = 'Erro ao carregar categorias';
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MimooD',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.black,
            fontSize: 28,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
            tooltip: 'Buscar Notícias',
          ),
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Alternar Tema',
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categoriesError.isNotEmpty || _categories.isEmpty
              ? CategoryFeed(categoryId: null) // Fallback to raw feed
              : DefaultTabController(
                  length: _categories.length + 1,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          const Tab(text: 'Tudo'),
                          ..._categories.map((cat) => Tab(text: cat.name)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            CategoryFeed(categoryId: null),
                            ..._categories.map((cat) => CategoryFeed(categoryId: cat.id)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// Category Feed Component with scroll controller for pagination
class CategoryFeed extends StatefulWidget {
  final int? categoryId;
  const CategoryFeed({super.key, required this.categoryId});

  @override
  State<CategoryFeed> createState() => _CategoryFeedState();
}

class _CategoryFeedState extends State<CategoryFeed> with AutomaticKeepAliveClientMixin {
  final WordpressService _wordpressService = WordpressService();
  final ScrollController _scrollController = ScrollController();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _error = '';
  int _page = 1;
  bool _hasMore = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _page = 1;
      _hasMore = true;
    });
    try {
      final posts = await _wordpressService.fetchPosts(page: _page, categoryId: widget.categoryId);
      setState(() {
        _posts = posts;
        _isLoading = false;
        if (posts.length < 10) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar notícias. Puxe para atualizar.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _page + 1;
      final morePosts = await _wordpressService.fetchPosts(page: nextPage, categoryId: widget.categoryId);
      setState(() {
        _page = nextPage;
        _posts.addAll(morePosts);
        _isLoadingMore = false;
        if (morePosts.length < 10) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar mais notícias')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInitialPosts,
                child: const Text('Tentar Novamente'),
              )
            ],
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(child: Text('Nenhuma notícia encontrada.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchInitialPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12.0),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = _posts[index];
          final formattedDate = DateFormat('dd/MM/yyyy').format(post.date);

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => context.go('/details/${post.id}'),
              borderRadius: BorderRadius.circular(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.featuredImageUrl != null)
                    Hero(
                      tag: 'post-img-${post.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                        child: Image.network(
                          post.featuredImageUrl!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${post.readingTime} min de leitura',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Html(
                          data: post.excerpt,
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              maxLines: 3,
                              textOverflow: TextOverflow.ellipsis,
                              fontSize: FontSize(14.0),
                              color: Colors.grey[700],
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Favorites Screen
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final WordpressService _wordpressService = WordpressService();
  List<Post> _favoritePosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final bookmarksProvider = Provider.of<BookmarksProvider>(context, listen: false);
    
    // Make sure bookmarks initialization has completed
    if (!bookmarksProvider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final ids = bookmarksProvider.bookmarkedIds;
    if (ids.isEmpty) {
      setState(() {
        _favoritePosts = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Post> fetched = [];
      for (String id in ids) {
        try {
          final post = await _wordpressService.fetchPost(id);
          fetched.add(post);
        } catch (e) {
          // If a specific post fails, skip it
        }
      }
      setState(() {
        _favoritePosts = fetched;
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
      appBar: AppBar(
        title: const Text('Itens Salvos'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favoritePosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma notícia salva ainda.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _favoritePosts.length,
                    itemBuilder: (context, index) {
                      final post = _favoritePosts[index];
                      final formattedDate = DateFormat('dd/MM/yyyy').format(post.date);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8.0),
                          leading: post.featuredImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    post.featuredImageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          title: Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '$formattedDate • ${post.readingTime} min',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await Provider.of<BookmarksProvider>(context, listen: false)
                                  .toggleBookmark(post.id);
                              _loadFavorites();
                            },
                          ),
                          onTap: () => context.go('/details/${post.id}'),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// Search Screen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final WordpressService _wordpressService = WordpressService();
  final TextEditingController _searchController = TextEditingController();
  List<Post> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final results = await _wordpressService.searchPosts(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao realizar busca.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar no portal MimooD...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchResults = []);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Digite termos para buscar notícias.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final post = _searchResults[index];
                        final formattedDate = DateFormat('dd/MM/yyyy').format(post.date);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: post.featuredImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      post.featuredImageUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            title: Text(
                              post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$formattedDate • ${post.readingTime} min'),
                            onTap: () => context.go('/details/${post.id}'),
                          ),
                        );
                      },
                    ),
    );
  }
}

// Detail Screen
class DetailScreen extends StatefulWidget {
  final String postId;
  const DetailScreen({super.key, required this.postId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Post> _postFuture;
  final WordpressService _wordpressService = WordpressService();

  @override
  void initState() {
    super.initState();
    _postFuture = _wordpressService.fetchPost(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(child: Text('Erro ao carregar notícia.')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Não Encontrado')),
            body: const Center(child: Text('Notícia não encontrada.')),
          );
        }

        final post = snapshot.data!;
        final formattedDate = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(post.date);

        return Consumer<BookmarksProvider>(
          builder: (context, bookmarksProvider, child) {
            final isSaved = bookmarksProvider.isBookmarked(post.id);

            return Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () => bookmarksProvider.toggleBookmark(post.id),
                    tooltip: isSaved ? 'Remover dos favoritos' : 'Salvar nos favoritos',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Share.share(
                        'Confira essa notícia: ${post.title}\n${post.link}',
                        subject: post.title,
                      );
                    },
                    tooltip: 'Compartilhar',
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.featuredImageUrl != null)
                      Hero(
                        tag: 'post-img-${post.id}',
                        child: Image.network(
                          post.featuredImageUrl!,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                '${post.readingTime} min de leitura',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            post.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const Divider(height: 40, thickness: 1),
                          Html(
                            data: post.content,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(16.0),
                                lineHeight: const LineHeight(1.6),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                              "p": Style(
                                margin: Margins.only(bottom: 16.0),
                              ),
                              "a": Style(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
