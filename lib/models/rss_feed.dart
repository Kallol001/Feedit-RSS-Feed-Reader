class RssFeed {
  final String title;
  final String link;
  final String description;
  final String pubDate;
  final String mediaUrl;
  final String contentType;
  final DateTime dateTime; // New field for storing parsed date and time

  RssFeed({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
    required this.mediaUrl,
    required this.contentType,
    required this.dateTime, // Initialize the parsed date and time
  });
}
