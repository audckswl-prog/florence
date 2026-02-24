class Memo {
  final String id;
  final String userId;
  final String isbn;
  final String content;
  final String? imageUrl;
  final int? pageNumber;
  final DateTime createdAt;

  Memo({
    required this.id,
    required this.userId,
    required this.isbn,
    required this.content,
    this.imageUrl,
    this.pageNumber,
    required this.createdAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'],
      userId: json['user_id'],
      isbn: json['isbn'],
      content: json['content'],
      imageUrl: json['image_url'],
      pageNumber: json['page_number'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'isbn': isbn,
      'content': content,
      'image_url': imageUrl,
      'page_number': pageNumber,
      // 'created_at': let Supabase handle default now()
    };
  }
}
