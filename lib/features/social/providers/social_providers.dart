import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';
import '../../library/providers/book_providers.dart';

final myProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  final data = await repository.getMyProjects(userId);
  // data is list of project_members with joined 'projects'
  return data.map((json) {
    final projectJson = json['projects'] as Map<String, dynamic>;
    return Project.fromJson(projectJson);
  }).toList();
});

final projectMembersProvider = FutureProvider.family<List<ProjectMember>, String>((ref, projectId) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final data = await repository.getProjectMembers(projectId);
  return data.map((json) => ProjectMember.fromJson(json)).toList();
});

final projectBooksProvider = FutureProvider.family<List<ProjectBook>, String>((ref, projectId) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final data = await repository.getProjectBooks(projectId);
  return data.map((json) => ProjectBook.fromJson(json)).toList();
});

// --- New Providers for Shared Reading Revamp ---

final friendsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return await repository.getFriends(userId);
});

final pendingFriendRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return await repository.getPendingFriendRequests(userId);
});

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return await repository.getNotifications(userId);
});

final profileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return await repository.getProfile(userId);
});

final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.watch(profileProvider(userId).future);
});
