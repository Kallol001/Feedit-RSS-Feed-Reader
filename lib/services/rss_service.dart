import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rss_feed.dart';

class RssService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RssFeed>> fetchRssFeeds(String userId) async {
    final List<RssFeed> feeds = [];
    final Set<String> uniqueTitles = {};
    final Set<String> uniqueLinks = {};

    try {
      // Fetch RSS links from Firestore using the provided userId
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rss_links')
          .get();

      final links = snapshot.docs.map((doc) => doc.data()['link'] as String);

      for (String link in links) {
        try {
          final response = await http.get(Uri.parse(link));
          if (response.statusCode == 200) {
            final document = XmlDocument.parse(response.body);
            final items = document.findAllElements('item');

            for (var item in items) {
              String rawTitle = item.findElements('title').first.text;
              String cleanTitle = _removeHtmlTags(rawTitle).trim();

              String rawDescription =
                  item.findElements('description').isNotEmpty
                      ? item.findElements('description').first.text
                      : '';
              String cleanDescription =
                  _truncateDescription(_removeHtmlTags(rawDescription));

              String imageUrl = _extractImageUrl(item);
              String contentType = _determineContentType(item);

              String pubDateStr = item.findElements('pubDate').first.text;
              DateTime dateTime = _parsePubDate(pubDateStr);

              String feedLink = item.findElements('link').first.text;

              if (!uniqueTitles.contains(cleanTitle) &&
                  !uniqueLinks.contains(feedLink)) {
                uniqueTitles.add(cleanTitle);
                uniqueLinks.add(feedLink);
                feeds.add(RssFeed(
                  title: cleanTitle,
                  link: feedLink,
                  description: cleanDescription,
                  pubDate: pubDateStr,
                  mediaUrl: imageUrl,
                  contentType: contentType,
                  dateTime: dateTime,
                ));
              }
            }
          }
        } catch (e) {
          print('Error fetching feed from $link: $e');
        }
      }

      feeds.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      print('Error fetching RSS links from Firestore: $e');
    }

    return feeds;
  }

  // Rest of the helper methods remain the same
  DateTime _parsePubDate(String pubDateStr) {
    try {
      final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z');
      return dateFormat.parse(pubDateStr);
    } catch (e) {
      print('Error parsing pubDate: $e');
      return DateTime.now();
    }
  }

  String _determineContentType(XmlElement item) {
    if (item.findElements('media:content').isNotEmpty) {
      final enclosure = item.findElements('media:content').first;
      final type = enclosure.getAttribute('type') ?? '';
      if (type.contains('video')) return 'video';
      if (type.contains('audio')) return 'audio';
    }
    if (item.findElements('enclosure').isNotEmpty) {
      final enclosure = item.findElements('enclosure').first;
      final type = enclosure.getAttribute('type') ?? '';
      if (type.contains('video')) return 'video';
      if (type.contains('audio')) return 'audio';
    }
    String link = item.findElements('link').first.text;
    if (link.contains('youtube.com') || link.contains('vimeo.com')) {
      return 'video';
    } else if (link.contains('soundcloud.com') ||
        link.contains('spotify.com')) {
      return 'audio';
    }
    return 'text';
  }

  String _removeHtmlTags(String html) {
    final RegExp exp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(exp, '').trim();
  }

  String _truncateDescription(String description) {
    return description.length > 150
        ? '${description.substring(0, 150)}...'
        : description;
  }

  String _extractImageUrl(XmlElement item) {
    try {
      if (item.findElements('media:content').isNotEmpty) {
        final mediaContent = item.findElements('media:content').first;
        final url = mediaContent.getAttribute('url');
        if (url != null && url.isNotEmpty) return url;
      }

      if (item.findElements('enclosure').isNotEmpty) {
        final enclosure = item.findElements('enclosure').first;
        final url = enclosure.getAttribute('url');
        if (url != null && url.isNotEmpty) return url;
      }

      final description = item.findElements('description').isNotEmpty
          ? item.findElements('description').first.text
          : '';
      if (description.isNotEmpty) {
        final imageUrls = _extractImagesFromDescription(description);
        if (imageUrls.isNotEmpty) return imageUrls.first;
      }

      if (item.findElements('image').isNotEmpty) {
        final imageTag = item.findElements('image').first.text;
        if (imageTag.isNotEmpty) return imageTag;
      }
    } catch (e) {
      print('Error extracting image URL: $e');
    }
    return '';
  }

  List<String> _extractImagesFromDescription(String description) {
    final RegExp imgRegExp =
        RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final matches = imgRegExp.allMatches(description);
    return matches.map((match) => match.group(1)!).toList();
  }
}
