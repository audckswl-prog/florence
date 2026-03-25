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

  Future<void> updateMemo(Memo memo) async {
    try {
      await _client.from('memos').update({
        'content': memo.content,
        'image_url': memo.imageUrl,
        'page_number': memo.pageNumber,
      }).eq('id', memo.id);
    } catch (e) {
      throw Exception('Error updating memo: $e');
    }
  }

  Future<void> deleteMemo(String memoId) async {
    try {
      await _client.from('memos').delete().eq('id', memoId);
    } catch (e) {
      throw Exception('Error deleting memo: $e');
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

  /// 두 유저 간 기존 friendship 상태를 확인합니다.
  /// 반환값: null (없음), 'pending', 'accepted'
  Future<String?> checkExistingFriendship(String userId1, String userId2) async {
    try {
      final response = await _client
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$userId1,receiver_id.eq.$userId2),and(requester_id.eq.$userId2,receiver_id.eq.$userId1)');

      if (response == null || (response as List).isEmpty) {
        return null;
      }
      return response[0]['status'] as String?;
    } catch (e) {
      debugPrint('[checkExistingFriendship] ERROR: $e');
      return null;
    }
  }

  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    try {
      final response = await _client.from('friendships').insert({
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': 'pending',
      }).select().single();

      final friendshipId = response['id'] as String;

      // Also send notification
      await createNotification(
        userId: receiverId,
        senderId: requesterId,
        type: 'friend_request',
        message: '새로운 친구 요청이 도착했습니다.',
        relatedId: friendshipId,
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

  Future<void> rejectFriendRequest(String friendshipId) async {
    try {
      await _client
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
    } catch (e) {
      throw Exception('Error rejecting friend request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      // 1) 내가 요청자인 accepted friendships
      final response1 = await _client
          .from('friendships')
          .select()
          .eq('requester_id', userId)
          .eq('status', 'accepted');
      // 2) 내가 수신자인 accepted friendships
      final response2 = await _client
          .from('friendships')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'accepted');

      List<Map<String, dynamic>> friends = [];
      final Set<String> addedFriendIds = {}; // 중복 필터링을 위한 Set

      // response1: 내가 requester → 상대방은 receiver
      for (final row in (response1 ?? [])) {
        final friendId = row['receiver_id'] as String?;
        if (friendId == null || addedFriendIds.contains(friendId)) continue;

        Map<String, dynamic>? profile;
        try {
          final profileData = await _client
              .from('profiles')
              .select()
              .eq('id', friendId)
              .maybeSingle();
          profile = profileData;
        } catch (_) {}

        addedFriendIds.add(friendId);
        friends.add({
          ...Map<String, dynamic>.from(row),
          'receiver': profile,
        });
      }

      // response2: 내가 receiver → 상대방은 requester
      for (final row in (response2 ?? [])) {
        final friendId = row['requester_id'] as String?;
        if (friendId == null || addedFriendIds.contains(friendId)) continue;

        Map<String, dynamic>? profile;
        try {
          final profileData = await _client
              .from('profiles')
              .select()
              .eq('id', friendId)
              .maybeSingle();
          profile = profileData;
        } catch (_) {}

        addedFriendIds.add(friendId);
        friends.add({
          ...Map<String, dynamic>.from(row),
          'requester': profile,
        });
      }

      debugPrint('[getFriends] Found ${friends.length} unique friends for $userId');
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
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      List<Map<String, dynamic>> results = [];
      for (final row in (response ?? [])) {
        final requesterId = row['requester_id'] as String?;
        Map<String, dynamic>? profile;
        if (requesterId != null) {
          try {
            profile = await _client
                .from('profiles')
                .select()
                .eq('id', requesterId)
                .maybeSingle();
          } catch (_) {}
        }
        results.add({
          ...Map<String, dynamic>.from(row),
          'requester': profile,
        });
      }
      return results;
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
      // Fetch base notifications without join
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> enriched = [];
      for (final row in response) {
        final senderId = row['sender_id'] as String?;
        if (senderId != null) {
          try {
            final profileData = await _client
                .from('profiles')
                .select()
                .eq('id', senderId)
                .maybeSingle();
            enriched.add({
              ...row,
              'sender': profileData,
            });
          } catch (_) {
            enriched.add(row);
          }
        } else {
          enriched.add(row);
        }
      }

      return enriched
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

  Future<void> markInformationalNotificationsAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false)
          .not('type', 'in', ['project_invite', 'friend_request']);
    } catch (e) {
      throw Exception('Error marking informational notifications as read: $e');
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

      // 3. Friends will join upon accepting the invite

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

        final res = await _client
            .from('projects')
            .update({
              'status': 'in_progress',
              'start_date': startDate.toIso8601String(),
              'end_date': endDate.toIso8601String(),
            })
            .eq('id', projectId)
            .select();
            
        if (res.isEmpty) {
          throw Exception('프로젝트 상태 업데이트에 실패했습니다. (RLS 권한 정책을 확인하세요)');
        }

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

  Future<void> deleteProject(String projectId) async {
    try {
      final res = await _client.from('projects').delete().eq('id', projectId).select();
      if (res.isEmpty) {
        throw Exception('삭제 권한이 없거나 이미 삭제되었습니다. (RLS 확인 필요)');
      }
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }

  Future<void> leaveProject(String projectId, String userId) async {
    try {
      final res = await _client
          .from('project_members')
          .delete()
          .match({'project_id': projectId, 'user_id': userId})
          .select();

      if (res.isEmpty) {
        throw Exception('나가기 실패: 권한이 없거나 멤버 레코드가 없습니다. (RLS 정책 확인 필요)');
      }

      // 나간 뒤 남은 멤버 확인
      final members = await _client
          .from('project_members')
          .select('id')
          .eq('project_id', projectId);

      if (members.isEmpty) {
        await deleteProject(projectId);
      }
    } catch (e) {
      throw Exception('Error leaving project: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    try {
      // Fetch members and books
      final response = await _client
          .from('project_members')
          .select('*, books(*)')
          .eq('project_id', projectId);
      return _enrichWithProfiles(response);
    } catch (e) {
      // Fallback: fetch without books join
      try {
        final response = await _client
            .from('project_members')
            .select()
            .eq('project_id', projectId);
        return _enrichWithProfiles(response);
      } catch (e2) {
        throw Exception('Error fetching project members: $e2');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _enrichWithProfiles(List<Map<String, dynamic>> members) async {
    List<Map<String, dynamic>> enriched = [];
    for (final row in members) {
      final memberUserId = row['user_id'] as String;
      final selectedIsbn = row['selected_isbn'] as String?;
      Map<String, dynamic> enrichedRow = {...row};
      try {
        final profileData = await _client
            .from('profiles')
            .select()
            .eq('id', memberUserId)
            .maybeSingle();
        enrichedRow['profiles'] = profileData;
      } catch (_) {}
      // Fetch user_books data for this member's selected book
      if (selectedIsbn != null) {
        try {
          final userBookData = await _client
              .from('user_books')
              .select()
              .eq('user_id', memberUserId)
              .eq('isbn', selectedIsbn)
              .maybeSingle();
          enrichedRow['user_book_data'] = userBookData;
        } catch (_) {}
      }
      enriched.add(enrichedRow);
    }
    return enriched;
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
        final res = await _client
            .from('projects')
            .update({
              'status': 'completed',
              'end_date': DateTime.now().toIso8601String(),
            })
            .eq('id', projectId)
            .select();
            
        if (res.isEmpty) {
          throw Exception('프로젝트 완수 업데이트에 실패했습니다. (RLS 권한 정책을 확인하세요)');
        }

        // 2. 프로젝트 성공 알림
        for (var m in members) {
          await createNotification(
            userId: m['user_id'],
            type: 'project_success',
            message: '프로젝트가 성공적으로 완료되어 독서 티켓이 발급되었습니다!',
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
          
      // 1. 모든 멤버가 티켓 작성을 마쳤는지 확인
      final isReady = await checkAllMembersTicketReady(projectId);
      if (isReady) {
        // 2. 다른 멤버들에게 프로젝트 성공(티켓 발급) 알림 전송
        final members = await _client.from('project_members').select().eq('project_id', projectId);
        for (var m in members) {
           final memberId = m['user_id'] as String;
           if (memberId != userId) {
               await createNotification(
                   userId: memberId,
                   senderId: userId,
                   type: 'project_success',
                   message: '모두 독서 티켓 작성을 완료했습니다! 발급된 티켓을 확인하세요.',
                   relatedId: projectId,
               );
           }
        }
      }
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
