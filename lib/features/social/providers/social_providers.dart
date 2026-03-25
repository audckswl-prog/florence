import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';
import '../../library/providers/book_providers.dart';
import 'package:flutter/material.dart';

final sharedReadingSearchFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});

final myProjectsProvider = FutureProvider.autoDispose<List<Project>>((
  ref,
) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  // Cleanup expired incomplete projects silently
  await repository.cleanupExpiredProjects(userId);

  final data = await repository.getMyProjects(userId);
  // data is list of project_members with joined 'projects'
  return data.map((json) {
    final projectJson = json['projects'] as Map<String, dynamic>;
    return Project.fromJson(projectJson);
  }).toList();
});

final projectMembersProvider =
    FutureProvider.autoDispose.family<List<ProjectMember>, String>((ref, projectId) async {
      final repository = ref.watch(supabaseRepositoryProvider);
      final data = await repository.getProjectMembers(projectId);
      return data.map((json) => ProjectMember.fromJson(json)).toList();
    });

final projectBooksProvider = FutureProvider.autoDispose.family<List<ProjectBook>, String>((
  ref,
  projectId,
) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final data = await repository.getProjectBooks(projectId);
  return data.map((json) => ProjectBook.fromJson(json)).toList();
});

// --- New Providers for Shared Reading Revamp ---

final friendsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return await repository.getFriends(userId);
});

final pendingFriendRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repository = ref.watch(supabaseRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];
      return await repository.getPendingFriendRequests(userId);
    });

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return await repository.getNotifications(userId);
});

final profileProvider = FutureProvider.family<Profile?, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return await repository.getProfile(userId);
});

final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.watch(profileProvider(userId).future);
});

/// 프로젝트 + 멤버(선택 도서 포함) 통합 데이터
class ProjectWithMembers {
  final Project project;
  final List<ProjectMember> members;

  ProjectWithMembers({required this.project, required this.members});

  /// 현재 사용자의 멤버 정보
  ProjectMember? getMe(String userId) =>
      members.where((m) => m.userId == userId).firstOrNull;

  /// 프로젝트에서 선택된 책 커버 중 첫 번째
  String? get firstBookCover {
    for (final m in members) {
      if (m.selectedBookCover != null && m.selectedBookCover!.isNotEmpty) {
        return m.selectedBookCover;
      }
    }
    return null;
  }

  /// 프로젝트에서 선택된 책 제목 중 첫 번째
  String? get firstBookTitle {
    for (final m in members) {
      if (m.selectedBookTitle != null && m.selectedBookTitle!.isNotEmpty) {
        return m.selectedBookTitle;
      }
    }
    return null;
  }
}

final myProjectsWithMembersProvider =
    FutureProvider.autoDispose<List<ProjectWithMembers>>((ref) async {
      final repository = ref.watch(supabaseRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Cleanup expired incomplete projects silently
      await repository.cleanupExpiredProjects(userId);

      final projectData = await repository.getMyProjects(userId);
      final projects = projectData.map((json) {
        final projectJson = json['projects'] as Map<String, dynamic>;
        return Project.fromJson(projectJson);
      }).toList();

      final result = <ProjectWithMembers>[];
      for (final project in projects) {
        final memberData = await repository.getProjectMembers(project.id);
        final members = memberData
            .map((json) => ProjectMember.fromJson(json))
            .toList();
        result.add(ProjectWithMembers(project: project, members: members));
      }
      return result;
    });
