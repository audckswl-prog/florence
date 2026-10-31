import '../models/book_model.dart';
import '../services/kakao_book_service.dart';
import '../services/national_library_service.dart';

abstract class BookRepository {
  Future<List<Book>> searchBooks(String query);
  Future<Book?> getBookDetail(String isbn);
}

class BookRepositoryImpl implements BookRepository {
  final KakaoBookService _kakaoBookService;
  final NationalLibraryService _nationalLibraryService;

  BookRepositoryImpl(this._kakaoBookService, this._nationalLibraryService);

  @override
  Future<List<Book>> searchBooks(String query) async {
    return await _kakaoBookService.searchBook(query);
  }

  @override
  Future<Book?> getBookDetail(String isbn) async {
    // 1. 카카오 API로 도서 기본 정보 조회
    final book = await _kakaoBookService.getBookByIsbn(isbn);
    if (book == null) return null;

    // 2. 국립중앙도서관 API로 페이지 수(쪽수) 조회
    final pageCount = await _nationalLibraryService.getPageCount(isbn);
    if (pageCount != null && pageCount > 0) {
      return book.copyWith(pageCount: pageCount);
    }

    return book;
  }
}
