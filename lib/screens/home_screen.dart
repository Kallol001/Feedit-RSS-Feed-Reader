import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/rss_feed.dart';
import '../screens/login.dart';
import '../services/rss_service.dart';
import '../widgets/feed_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RssFeed> _allFeeds = [];
  List<RssFeed> _textFeeds = [];
  List<RssFeed> _audioFeeds = [];
  List<RssFeed> _videoFeeds = [];
  final TextEditingController _rssLinkController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  List<String> _rssLinks = [];
  List<String> _customNames = [];
  bool _isLoading = true;
  String? _userId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _loadExistingRssLinks();
      await _fetchFeeds();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rssLinkController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeds() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rssService = RssService();
      List<RssFeed> feeds = await rssService.fetchRssFeeds(_userId!);

      setState(() {
        _allFeeds = feeds;
        _textFeeds = feeds.where((feed) => feed.contentType == 'text').toList();
        _audioFeeds =
            feeds.where((feed) => feed.contentType == 'audio').toList();
        _videoFeeds =
            feeds.where((feed) => feed.contentType == 'video').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching feeds: $e')),
      );
    }
  }

  Future<void> _loadExistingRssLinks() async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rss_links')
          .get();

      setState(() {
        _rssLinks = snapshot.docs.map((doc) => doc['link'] as String).toList();
        _customNames =
            snapshot.docs.map((doc) => doc['customName'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading RSS links: $e')),
      );
    }
  }

  void _showAddRssDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New RSS Link'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 700,
                height: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rssLinks.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              '${_customNames[index]} (${_rssLinks[index]})',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRssLink(
                                  _rssLinks[index], _customNames[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: _customNameController,
                      decoration:
                          const InputDecoration(labelText: 'Enter Custom Name'),
                    ),
                    TextField(
                      controller: _rssLinkController,
                      decoration: const InputDecoration(
                          labelText: 'Enter RSS Feed Link'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _addRssLink(_rssLinkController.text.trim(),
                                _customNameController.text.trim());
                            _rssLinkController.clear();
                            _customNameController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addRssLink(String link, String customName) async {
    if (_userId == null) return;

    if (link.isNotEmpty && customName.isNotEmpty && !_rssLinks.contains(link)) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('rss_links')
            .add({
          'link': link,
          'customName': customName,
        });

        await _loadExistingRssLinks();
        _fetchFeeds();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding RSS link: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(link.isEmpty || customName.isEmpty
              ? 'Please enter a valid RSS link and custom name!'
              : 'This RSS link is already present!'),
        ),
      );
    }
  }

  Future<void> _deleteRssLink(String link, String customName) async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('rss_links')
          .where('link', isEqualTo: link)
          .where('customName', isEqualTo: customName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await _loadExistingRssLinks();
      _fetchFeeds();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting RSS link: $e')),
      );
    }
  }

  void _refreshFeeds() {
    _fetchFeeds();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feeds refreshed!')),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshFeeds,
        ),
        title: const Padding(
          padding: EdgeInsets.only(
            top: 20.0, // Padding on top
            bottom: 10.0, // Padding on bottom
            left: 55.0, // Padding on left
            right: 16.0, // Padding on right
          ),
          child: Center(
            child: Text(
              'Feedit',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 120, 2, 153),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nights_stay,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Text'),
            Tab(text: 'Audio'),
            Tab(text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(_textFeeds),
          _buildFeedList(_audioFeeds),
          _buildFeedList(_videoFeeds),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRssDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedList(List<RssFeed> feeds) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feeds.isEmpty) {
      return const Center(
        child: Text(
          'No feeds available. Add an RSS link to get started!',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        return FeedCard(feed: feeds[index]);
      },
    );
  }
}
