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

  /// 알라딘/카카오 API 썸네일 URL을 고화질(cover500 또는 R500x0)로 자동 변환.
  /// 앱 전체에서 이 getter를 사용하면 일관된 고화질 표지를 보장합니다.
  String get highResCoverUrl {
    if (coverUrl.contains('aladin.co.kr')) {
      return coverUrl.replaceAll(
        RegExp(r'coversum|cover150|cover200'),
        'cover500',
      );
    }
    // 카카오 도서 썸네일 고화질 변환 (R120x174 -> R500x0)
    if (coverUrl.contains('kakaocdn.net/thumb/')) {
      return coverUrl.replaceAll(RegExp(r'R\d+x\d+'), 'R500x0');
    }
    return coverUrl;
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

  Book copyWith({
    String? title,
    String? author,
    String? pubDate,
    String? description,
    String? isbn,
    String? coverUrl,
    String? publisher,
    String? categoryName,
    String? link,
    int? pageCount,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      pubDate: pubDate ?? this.pubDate,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      publisher: publisher ?? this.publisher,
      categoryName: categoryName ?? this.categoryName,
      link: link ?? this.link,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  factory Book.fromKakaoJson(Map<String, dynamic> json) {
    // 저자 파싱
    String authorStr = '';
    if (json['authors'] is List) {
      authorStr = (json['authors'] as List).join(', ');
    } else if (json['authors'] is String) {
      authorStr = json['authors'];
    }

    // 출판일 파싱 (2011-04-03T00:00:00.000+09:00 -> 2011-04-03)
    String pubDate = json['datetime'] ?? '';
    if (pubDate.length >= 10) {
      pubDate = pubDate.substring(0, 10);
    }

    // ISBN 파싱 (예: "8937462672 9788937462672" 중 13자리 우선 추출)
    String isbnRaw = (json['isbn'] ?? '').toString().trim();
    String isbn = isbnRaw;
    final parts = isbnRaw.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      final isbn13 = parts.firstWhere(
        (p) => p.length == 13,
        orElse: () => parts.last,
      );
      isbn = isbn13;
    }

    return Book(
      title: json['title'] ?? '',
      author: authorStr,
      pubDate: pubDate,
      description: json['contents'] ?? '',
      isbn: isbn,
      coverUrl: json['thumbnail'] ?? '',
      publisher: json['publisher'] ?? '',
      categoryName: '',
      link: json['url'] ?? '',
      pageCount: 0,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    // If it's kakao document structure
    if (json.containsKey('contents') && json.containsKey('authors')) {
      return Book.fromKakaoJson(json);
    }

    return Book(
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      pubDate:
          json['pubDate'] ??
          json['pub_date'] ??
          '', // Handle both camelCase (API) and snake_case (DB)
      description: json['description'] ?? '',
      isbn: json['isbn13'] ?? json['isbn'] ?? '',
      coverUrl: json['cover'] ?? json['cover_url'] ?? '',
      publisher: json['publisher'] ?? '',
      categoryName: json['categoryName'] ?? json['category_name'] ?? '',
      link: json['link'] ?? '',
      pageCount:
          json['subInfo']?['itemPage'] ??
          json['itemPage'] ??
          json['page_count'] ??
          0,
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
