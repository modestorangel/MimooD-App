import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:share_plus/share_plus.dart';
import 'services/wordpress_service.dart';
import 'models/post_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
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

// Router configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'details/:id',
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return DetailScreen(postId: id);
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
    const Color primarySeedColor = Colors.blue;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'MimooD',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primarySeedColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        )
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        )
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WordpressService _wordpressService = WordpressService();
  List<Post> _posts = [];
  List<Post> _searchResults = [];
  bool _isLoading = true;
  String _error = '';
  final FloatingSearchBarController _searchController = FloatingSearchBarController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final posts = await _wordpressService.fetchPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error fetching posts. Pull down to try again.';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchPosts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await _wordpressService.searchPosts(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle search error silently or show a snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: FloatingSearchBar(
        controller: _searchController,
        hint: 'Search posts...',
        scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
        transitionDuration: const Duration(milliseconds: 800),
        transitionCurve: Curves.easeInOut,
        physics: const BouncingScrollPhysics(),
        axisAlignment: 0.0,
        openAxisAlignment: 0.0,
        width: 600,
        debounceDelay: const Duration(milliseconds: 500),
        onQueryChanged: (query) {
          _searchPosts(query);
        },
        transition: CircularFloatingSearchBarTransition(),
        actions: [
          FloatingSearchBarAction.searchToClear(showIfClosed: false),
        ],
        builder: (context, transition) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Theme.of(context).cardColor,
              elevation: 4.0,
              child: _buildPostList(_searchResults.isNotEmpty ? _searchResults : _posts, isSearch: _searchResults.isNotEmpty),
            ),
          );
        },
        body: RefreshIndicator(
          onRefresh: _fetchPosts,
          child: _buildPostList(_posts)
        ),
        floatingBox: false,
        isScrollControlled: true,
        appBar: AppBar(
          title: const Text('MimooD News'),
          actions: [
            IconButton(
              icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: 'Toggle Theme',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(List<Post> posts, {bool isSearch = false}) {
     if (_isLoading && !isSearch) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty && !isSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPosts,
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }
    if (posts.isEmpty) {
      return Center(child: Text(isSearch ? 'No results found.' : 'No posts found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 70.0), // Adjust top padding to avoid overlap with search bar
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: InkWell(
            onTap: () => context.go('/details/${post.id}'),
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.featuredImageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                    child: Image.network(
                      post.featuredImageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Html(data: post.excerpt, style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          maxLines: 3,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


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
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Error loading post.')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Post not found.')),
          );
        }

        final post = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(
                    'Check out this post: ${post.title}\n${post.link}',
                    subject: post.title,
                  );
                },
                tooltip: 'Share Post',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.featuredImageUrl != null)
                  Image.network(
                    post.featuredImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink(); // Hide if image fails to load
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Html(data: post.content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
