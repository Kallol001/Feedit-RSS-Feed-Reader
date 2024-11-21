import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // For InAppWebView
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // For opening new tabs on the web

import '../models/rss_feed.dart';

class FeedCard extends StatefulWidget {
  final RssFeed feed;

  const FeedCard({super.key, required this.feed});

  @override
  _FeedCardState createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _isHovered = false; // State to track hover status

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 875,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              _showArticleDialog(context, widget.feed.link);
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkTheme
                          ? Colors.black.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  color: _isHovered
                      ? (isDarkTheme ? Colors.grey[700] : Colors.grey[300])
                      : (isDarkTheme ? Colors.black54 : Colors.white),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 600;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: widget.feed.mediaUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: isWideScreen ? 270 : 200,
                                    child: Image.network(
                                      widget.feed.mediaUrl,
                                      fit: BoxFit.cover,
                                      color: Colors.black.withOpacity(0.3),
                                      colorBlendMode: BlendMode.darken,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: isWideScreen ? 270 : 200,
                                  decoration: BoxDecoration(
                                    color: isDarkTheme
                                        ? Colors.grey[850]
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: const Center(child: Text('No Image')),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.feed.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWideScreen ? 18.0 : 16.0,
                                  color:
                                      isDarkTheme ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                widget.feed.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDarkTheme
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _formatDate(
                                    widget.feed.dateTime, widget.feed.pubDate),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isDarkTheme
                                      ? Colors.white54
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime, String pubDateStr) {
    if (pubDateStr.contains("GMT")) {
      final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('hh:mm a, dd MMM yyyy').format(istDateTime);
    }
    return DateFormat('hh:mm a, dd MMM yyyy').format(dateTime);
  }

  void _showArticleDialog(BuildContext context, String url) {
    if (kIsWeb) {
      // Open in a new browser tab for web
      _openInNewTab(url);
    } else {
      // Show a dialog with InAppWebView for mobile
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(url)),
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        useOnDownloadStart: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _openInNewTab(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle error if the URL can't be launched
      print('Could not launch $url');
    }
  }
}
