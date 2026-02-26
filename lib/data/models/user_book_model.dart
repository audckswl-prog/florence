import 'book_model.dart';

class UserBook {
  final String id;
  final String userId;
  final String isbn;
  final String status; // reading, read, wish
  final double? rating;
  final int readPages;
  final int? totalPages;
  final int readCount;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? quote;
  final Book book;

  UserBook({
    required this.id,
    required this.userId,
    required this.isbn,
    required this.status,
    this.rating,
    this.readPages = 0,
    this.totalPages,
    this.readCount = 1,
    this.startedAt,
    this.finishedAt,
    this.quote,
    required this.book,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'],
      userId: json['user_id'],
      isbn: json['isbn'],
      status: json['status'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      readPages: json['read_pages'] != null ? (json['read_pages'] as num).toInt() : 0,
      totalPages: json['total_pages'] != null ? (json['total_pages'] as num).toInt() : null,
      readCount: json['read_count'] != null ? (json['read_count'] as num).toInt() : 1,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      finishedAt: json['finished_at'] != null ? DateTime.parse(json['finished_at']) : null,
      quote: json['quote'] as String?,
      book: Book.fromJson(json['books']), // Assumes 'books' is the joined table alias
    );
  }
}
