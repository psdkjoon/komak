class StoreEntry {
  const StoreEntry({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;

  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}
