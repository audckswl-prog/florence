class AITicketModel {
  final String isbn;
  final String nationalityCode; // e.g., 'US', 'KR', 'GB'
  final String nationalityName; // e.g., '미국', '한국', '영국'
  final String publicationYear; // e.g., '2009년'

  AITicketModel({
    required this.isbn,
    required this.nationalityCode,
    required this.nationalityName,
    required this.publicationYear,
  });

  factory AITicketModel.fromJson(Map<String, dynamic> json) {
    return AITicketModel(
      isbn: json['isbn'] ?? '',
      nationalityCode: json['nationality_code'] ?? 'UN',
      nationalityName: json['nationality_name'] ?? '알 수 없음',
      publicationYear: json['publication_year'] ?? '연도 미상',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'nationality_code': nationalityCode,
      'nationality_name': nationalityName,
      'publication_year': publicationYear,
    };
  }
}
