class Book {
  final String title;
  final String author;
  final String pubDate;
  final String description;
  final String isbn;
  final String coverUrl;
  final String publisher;
  final String categoryName;
  final String link;
  final int pageCount;
  
  String get publicationYear {
    if (pubDate.length >= 4) {
      return pubDate.substring(0, 4);
    }
    return '연도 미상';
  }

  Book({
    required this.title,
    required this.author,
    required this.pubDate,
    required this.description,
    required this.isbn,
    required this.coverUrl,
    required this.publisher,
    required this.categoryName,
    required this.link,
    this.pageCount = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      pubDate: json['pubDate'] ?? json['pub_date'] ?? '', // Handle both camelCase (API) and snake_case (DB)
      description: json['description'] ?? '',
      isbn: json['isbn13'] ?? json['isbn'] ?? '',
      coverUrl: json['cover'] ?? json['cover_url'] ?? '',
      publisher: json['publisher'] ?? '',
      categoryName: json['categoryName'] ?? json['category_name'] ?? '',
      link: json['link'] ?? '',
      pageCount: json['subInfo']?['itemPage'] ?? json['itemPage'] ?? json['page_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'pub_date': pubDate,
      'description': description,
      'isbn': isbn,
      'cover_url': coverUrl,
      'publisher': publisher,
      'category_name': categoryName,
      'link': link,
      'page_count': pageCount,
    };
  }
}
