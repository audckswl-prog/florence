import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';
import '../models/book_model.dart';
import '../models/memo_model.dart';
import '../models/project_model.dart';
import '../models/profile_model.dart';
import '../models/friendship_model.dart';
import '../models/notification_model.dart';

class SupabaseRepository {
  final SupabaseClient _client;

  SupabaseRepository(this._client);

  Future<void> saveBook(Book book) async {
    try {
      // ignoreDuplicates: false → allows updating page_count if it was previously 0
      await _client.from('books').upsert(book.toJson(), onConflict: 'isbn');
    } catch (e) {
      throw Exception('Error saving book to Supabase: $e');
    }
  }

  /// Get a book from the books table by ISBN (cached data)
  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final data = await _client
          .from('books')
          .select()
          .eq('isbn', isbn)
          .maybeSingle();
      if (data != null) {
        return Book.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> addUserBook({
    required String userId,
    required Book book,
    required String status,
    int readPages = 0,
    int? totalPages,
    int readCount = 1,
  }) async {
    try {
      // 1. Ensure book exists in 'books' table
      await saveBook(book);

      // 2. Link book to user in 'user_books' table
      await _client.from('user_books').upsert({
        'user_id': userId,
        'isbn': book.isbn,
        'status': status,
        'read_pages': readPages,
        'total_pages': totalPages,
        'read_count': readCount,
        'started_at': status == 'reading'
            ? DateTime.now().toIso8601String()
            : null,
        'finished_at': status == 'read'
            ? DateTime.now().toIso8601String()
            : null,
      }, onConflict: 'user_id, isbn');
    } catch (e) {
      throw Exception('Error adding user book: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserBooks(
    String userId, {
    String? status,
  }) async {
    try {
      var query = _client
          .from('user_books')
          .select('*, books(*)')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      return await query;
    } catch (e) {
      throw Exception('Error fetching user books: $e');
    }
  }

  Future<void> updateUserBookStatus(
    String userId,
    String isbn,
    String status, {
    int? readPages,
    int? totalPages,
    int? readCount,
    String? quote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'finished_at': status == 'read'
            ? DateTime.now().toIso8601String()
            : null,
      };

      if (readPages != null) updates['read_pages'] = readPages;
      if (totalPages != null) updates['total_pages'] = totalPages;
      if (readCount != null) updates['read_count'] = readCount;
      if (quote != null) updates['quote'] = quote;

      if (status == 'reading') {
        updates['started_at'] = DateTime.now().toIso8601String();
      }

      await _client.from('user_books').update(updates).match({
        'user_id': userId,
        'isbn': isbn,
      });
    } catch (e) {
      throw Exception('Error updating user book status: $e');
    }
  }

  Future<void> deleteUserBook(String userId, String isbn) async {
    try {
      await _client.from('user_books').delete().match({
        'user_id': userId,
        'isbn': isbn,
      });
    } catch (e) {
      throw Exception('Error deleting user book: $e');
    }
  }

  Future<String?> uploadMemoImage(String userId, XFile imageFile) async {
    try {
      final fileExt = imageFile.name.split('.').last;
      final fileName =
          '${DateTime.now().toIso8601String().replaceAll(':', '-')}_$userId.$fileExt';
      final filePath = '$userId/$fileName';

      final bytes = await imageFile.readAsBytes();
      await _client.storage
          .from('memo_images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _client.storage
          .from('memo_images')
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> saveMemo(Memo memo) async {
    try {
      await _client.from('memos').insert({
        'user_id': memo.userId,
        'isbn': memo.isbn,
        'content': memo.content,
        'image_url': memo.imageUrl,
        'page_number': memo.pageNumber,
      });
    } catch (e) {
      throw Exception('Error saving memo: $e');
    }
  }

  Future<List<Memo>> getMemos(String userId, String isbn) async {
    try {
      final response = await _client
          .from('memos')
          .select()
          .eq('user_id', userId)
          .eq('isbn', isbn)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Memo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching memos: $e');
    }
  }

  // --- Profile Methods ---

  Future<void> createOrUpdateProfile(
    String userId,
    String nickname, {
    String? profileUrl,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': userId,
        'nickname': nickname,
        'profile_url': profileUrl,
      });
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Profile?> getProfileByNickname(String nickname) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('nickname', nickname)
          .maybeSingle();
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Error finding profile by nickname: $e');
    }
  }

  Future<List<Profile>> searchProfilesByNickname(String nicknameQuery) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .ilike('nickname', '%$nicknameQuery%')
          .neq('id', _client.auth.currentUser!.id); // Exclude self

      return (response as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error searching profiles: $e');
    }
  }

  Future<void> uploadProfileImage(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$userId/$fileName';

      // Upload to 'avatars' bucket
      await _client.storage
          .from('avatars')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // Update profile
      await _client
          .from('profiles')
          .update({'profile_url': publicUrl})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }

  // --- Friendship Methods ---

  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    try {
      await _client.from('friendships').insert({
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      // Also send notification
      await createNotification(
        userId: receiverId,
        senderId: requesterId,
        type: 'friend_request',
        message: '새로운 친구 요청이 도착했습니다.',
      );
    } catch (e) {
      throw Exception('Error sending friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(
    String friendshipId,
    String requesterId,
    String receiverId,
  ) async {
    try {
      await _client
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', friendshipId);

      // Send notification back to requester
      await createNotification(
        userId: requesterId,
        senderId: receiverId,
        type: 'friend_accept', // Using generic type, or similar
        message: '친구가 되었습니다!',
        relatedId: friendshipId,
      );
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      // Query where user is either requester or receiver and status is accepted
      final response1 = await _client
          .from('friendships')
          .select('*, receiver:profiles!receiver_id(*)')
          .eq('requester_id', userId)
          .eq('status', 'accepted');
      final response2 = await _client
          .from('friendships')
          .select('*, requester:profiles!requester_id(*)')
          .eq('receiver_id', userId)
          .eq('status', 'accepted');

      debugPrint('[getFriends] userId: $userId');
      debugPrint('[getFriends] response1 (I sent): ${response1?.length ?? 0} rows => $response1');
      debugPrint('[getFriends] response2 (I received): ${response2?.length ?? 0} rows => $response2');

      // Also check ALL friendships for this user regardless of status
      final allFriendships = await _client
          .from('friendships')
          .select()
          .or('requester_id.eq.$userId,receiver_id.eq.$userId');
      debugPrint('[getFriends] ALL friendships for user: ${allFriendships?.length ?? 0} rows => $allFriendships');

      List<Map<String, dynamic>> friends = [];
      if (response1 != null)
        friends.addAll(List<Map<String, dynamic>>.from(response1));
      if (response2 != null)
        friends.addAll(List<Map<String, dynamic>>.from(response2));
      return friends;
    } catch (e) {
      debugPrint('[getFriends] ERROR: $e');
      throw Exception('Error fetching friends: $e');
    }
  }

  /// 임시 디버그용: 모든 friendship 행을 가져와서 문자열로 반환
  Future<String> debugGetAllFriendships(String userId) async {
    try {
      final all = await _client
          .from('friendships')
          .select()
          .or('requester_id.eq.$userId,receiver_id.eq.$userId');
      if (all == null || all.isEmpty) {
        return 'friendships 테이블에 해당 유저 데이터 없음 (0행)';
      }
      final buf = StringBuffer('총 ${all.length}행:\n');
      for (final row in all) {
        buf.writeln('  id:${row['id']}, req:${row['requester_id']?.toString().substring(0, 8)}, '
            'recv:${row['receiver_id']?.toString().substring(0, 8)}, status:${row['status']}');
      }
      return buf.toString();
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('friendships')
          .select('*, requester:profiles!requester_id(*)')
          .eq('receiver_id', userId)
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching friend requests: $e');
    }
  }

  // --- Notification Methods ---

  Future<void> createNotification({
    required String userId,
    String? senderId,
    required String type,
    String? message,
    String? relatedId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'sender_id': senderId,
        'type': type,
        'message': message,
        'related_id': relatedId,
      });
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*, sender:profiles!sender_id(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // --- Project Methods ---

  Future<String> createProject({
    required String name,
    required String ownerId,
    required List<String> friendIds,
  }) async {
    try {
      // 1. Create the project with 'pending_books' status
      final projectResponse = await _client
          .from('projects')
          .insert({
            'name': name,
            'owner_id': ownerId,
            'status': 'pending_books',
          })
          .select()
          .single();

      final projectId = projectResponse['id'];

      // 2. Add owner as member
      await _client.from('project_members').insert({
        'project_id': projectId,
        'user_id': ownerId,
        'role': 'owner',
        'reading_status': 'reading',
      });

      // 3. Add all friends as members
      for (final friendId in friendIds) {
        await _client.from('project_members').insert({
          'project_id': projectId,
          'user_id': friendId,
          'role': 'member',
          'reading_status': 'reading',
        });
      }

      // 4. Send notifications to all friends
      for (final friendId in friendIds) {
        await createNotification(
          userId: friendId,
          senderId: ownerId,
          type: 'project_invite',
          message: '새로운 함께 읽기 프로젝트에 초대되었습니다!',
          relatedId: projectId,
        );
      }

      return projectId;
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  Future<bool> selectProjectBook({
    required String projectId,
    required String userId,
    required Book book,
  }) async {
    try {
      // Ensure book exists in global books table
      await saveBook(book);

      // Also add to user_books so progress tracking works
      await addUserBook(
        userId: userId,
        book: book,
        status: 'reading',
        totalPages: book.pageCount > 0 ? book.pageCount : null,
      );

      // Update project member's selected book
      await _client
          .from('project_members')
          .update({'selected_isbn': book.isbn})
          .match({'project_id': projectId, 'user_id': userId});

      // Check if both members have selected a book
      final members = await _client
          .from('project_members')
          .select()
          .eq('project_id', projectId);

      bool bothSelected = true;
      for (var member in members) {
        if (member['selected_isbn'] == null) {
          bothSelected = false;
          break;
        }
      }

      if (bothSelected) {
        // Start the project!
        final startDate = DateTime.now();
        final endDate = startDate.add(const Duration(days: 14)); // 2주 기한

        await _client
            .from('projects')
            .update({
              'status': 'in_progress',
              'start_date': startDate.toIso8601String(),
              'end_date': endDate.toIso8601String(),
            })
            .eq('id', projectId);

        // Notify both users
        for (var member in members) {
          await createNotification(
            userId: member['user_id'],
            type: 'project_started',
            message: '함께 읽기 프로젝트가 시작되었습니다! 2주 안에 완독에 도전하세요.',
            relatedId: projectId,
          );
        }
        return true; // Project started!
      }
      return false; // Waiting for the other member
    } catch (e) {
      // Re-throw
      throw Exception('Error selecting project book: $e');
    }
  }

  Future<void> joinProject(String projectId, String userId) async {
    try {
      await _client.from('project_members').insert({
        'project_id': projectId,
        'user_id': userId,
        'role': 'member',
        'reading_status': 'reading',
      });
    } catch (e) {
      throw Exception('Error joining project: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyProjects(String userId) async {
    try {
      final response = await _client
          .from('project_members')
          .select('''
        *,
        projects (*)
      ''')
          .eq('user_id', userId);

      return response;
    } catch (e) {
      throw Exception('Error fetching my projects: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    try {
      // Try joining with books table for cover/title info
      final response = await _client
          .from('project_members')
          .select('*, books(*)')
          .eq('project_id', projectId);
      return response;
    } catch (e) {
      // Fallback: fetch without join if FK relationship is not found
      try {
        final response = await _client
            .from('project_members')
            .select()
            .eq('project_id', projectId);
        return response;
      } catch (e2) {
        throw Exception('Error fetching project members: $e2');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getProjectBooks(String projectId) async {
    try {
      final response = await _client
          .from('project_books')
          .select('''
        *,
        books (*)
      ''')
          .eq('project_id', projectId);
      return response;
    } catch (e) {
      throw Exception('Error fetching project books: $e');
    }
  }

  Future<void> syncProjectReadingProgress({
    required String projectId,
    required String userId,
    required String isbn,
    required int readPages,
    required int totalPages,
    String? quote,
  }) async {
    try {
      // 1. Sync to user_books
      await updateUserBookStatus(
        userId,
        isbn,
        'reading',
        readPages: readPages,
        totalPages: totalPages,
      );

      // 2. Fetch friend to optionally notify
      final members = await _client
          .from('project_members')
          .select()
          .eq('project_id', projectId);
      String? friendId;
      for (var m in members) {
        if (m['user_id'] != userId) {
          friendId = m['user_id'];
          break;
        }
      }

      // 3. If milestone reached (every 100 pages), notify friend
      // We can do a rudimentary check here or simply trust the UI to call a separate notify method.
      // For now, we update the progress. Realistically, we might want to store project_members' read_pages if we don't want to always join user_books.
      // Wait, user_books read_pages IS the truth, we don't need to duplicate it in project_members.

      // If completed
      if (readPages >= totalPages && totalPages > 0) {
        await updateReadingStatus(projectId, userId, 'completed');
        await updateUserBookStatus(
          userId,
          isbn,
          'read',
          readPages: readPages,
          totalPages: totalPages,
          quote: quote,
        );

        await checkProjectCompletion(projectId);
      }
    } catch (e) {
      throw Exception('Error syncing reading progress: $e');
    }
  }

  Future<void> checkProjectCompletion(String projectId) async {
    try {
      final members = await _client
          .from('project_members')
          .select()
          .eq('project_id', projectId);
      bool allCompleted = true;
      for (var m in members) {
        if (m['reading_status'] != 'completed') {
          allCompleted = false;
          break;
        }
      }

      if (allCompleted) {
        // 1. 프로젝트 상태를 completed로 변경 + end_date 기록
        await _client
            .from('projects')
            .update({
              'status': 'completed',
              'end_date': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId);

        // 2. 각 멤버의 선택 도서를 모든 멤버의 서재에 'read' 상태로 추가
        // (자기 책은 이미 있지만 upsert로 안전하게 처리)
        final isbns = <String>{};
        for (var m in members) {
          final isbn = m['selected_isbn'] as String?;
          if (isbn != null) isbns.add(isbn);
        }

        for (final isbn in isbns) {
          final book = await getBookByIsbn(isbn);
          if (book != null) {
            for (var m in members) {
              await addUserBook(
                userId: m['user_id'],
                book: book,
                status: 'read',
                totalPages: book.pageCount > 0 ? book.pageCount : null,
              );
            }
          }
        }

        // 3. 프로젝트 성공 알림
        for (var m in members) {
          await createNotification(
            userId: m['user_id'],
            type: 'project_success',
            message: '프로젝트 성공! 독서 티켓이 발급되었습니다. 읽은 책이 서재에 추가되었어요.',
            relatedId: projectId,
          );
        }
      }
    } catch (e) {
      throw Exception('Error checking project completion: $e');
    }
  }

  Future<void> updateReadingStatus(
    String projectId,
    String userId,
    String status,
  ) async {
    try {
      await _client
          .from('project_members')
          .update({'reading_status': status})
          .match({'project_id': projectId, 'user_id': userId});
    } catch (e) {
      throw Exception('Error updating reading status: $e');
    }
  }

  // --- AI QnA Methods ---

  Future<void> saveAiQnaLog(
    String projectId,
    String userId,
    String question,
    String answer,
  ) async {
    try {
      await _client.from('ai_qna_logs').insert({
        'project_id': projectId,
        'user_id': userId,
        'question': question,
        'answer': answer,
      });

      // Also increment the question count for this user
      await incrementAiQuestionCount(projectId, userId);
    } catch (e) {
      throw Exception('Error saving AI QnA log: $e');
    }
  }

  Future<void> incrementAiQuestionCount(String projectId, String userId) async {
    try {
      // Note: In a production environment, you'd use a Postgres RPC call for atomicity,
      // but for simplicity here we fetch the current count and update it.
      final member = await _client
          .from('project_members')
          .select('ai_question_count')
          .match({'project_id': projectId, 'user_id': userId})
          .single();

      final currentCount = member['ai_question_count'] as int? ?? 0;
      await _client
          .from('project_members')
          .update({'ai_question_count': currentCount + 1})
          .match({'project_id': projectId, 'user_id': userId});
    } catch (e) {
      throw Exception('Error incrementing AI question count: $e');
    }
  }

  // --- Invite Methods ---

  Future<String> createProjectInvite(String projectId, int expireDays) async {
    try {
      final expiresAt = DateTime.now()
          .add(Duration(days: expireDays))
          .toIso8601String();
      final response = await _client
          .from('project_invites')
          .insert({'project_id': projectId, 'expires_at': expiresAt})
          .select()
          .single();

      return response['id']; // Return the unique invite ID
    } catch (e) {
      throw Exception('Error creating project invite: $e');
    }
  }

  /// Update a member's quote and/or drawing URL for the shared reading ticket
  Future<void> updateMemberTicketData(
    String projectId,
    String userId, {
    String? quote,
    String? drawingUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (quote != null) updates['quote'] = quote;
      if (drawingUrl != null) updates['drawing_url'] = drawingUrl;
      if (updates.isEmpty) return;

      await _client
          .from('project_members')
          .update(updates)
          .match({'project_id': projectId, 'user_id': userId});
    } catch (e) {
      throw Exception('Error updating member ticket data: $e');
    }
  }

  /// Upload a drawing image to Supabase Storage and return the public URL
  Future<String> uploadDrawingImage(
    String projectId,
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final fileName =
          'drawing_${projectId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$userId/$fileName';

      await _client.storage
          .from('memo_images')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _client.storage
          .from('memo_images')
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading drawing: $e');
    }
  }

  /// Check if all members of a project have submitted their quote and drawing
  Future<bool> checkAllMembersTicketReady(String projectId) async {
    try {
      final members = await _client
          .from('project_members')
          .select()
          .eq('project_id', projectId);

      for (var m in members) {
        if (m['quote'] == null || m['drawing_url'] == null) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw Exception('Error checking ticket readiness: $e');
    }
  }
}
