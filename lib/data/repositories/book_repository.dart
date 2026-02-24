import '../models/book_model.dart';
import '../services/aladin_service.dart';

abstract class BookRepository {
  Future<List<Book>> searchBooks(String query);
  Future<Book?> getBookDetail(String isbn);
}

class BookRepositoryImpl implements BookRepository {
  final AladinService _aladinService;

  BookRepositoryImpl(this._aladinService);

  @override
  Future<List<Book>> searchBooks(String query) async {
    return await _aladinService.searchBook(query);
  }

  @override
  Future<Book?> getBookDetail(String isbn) async {
    return await _aladinService.getBookDetail(isbn);
  }
}
