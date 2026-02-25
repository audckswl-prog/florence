import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../social/providers/social_providers.dart';
import '../../library/providers/book_providers.dart';

class SharedReadingHeader extends ConsumerStatefulWidget {
  const SharedReadingHeader({super.key});

  @override
  ConsumerState<SharedReadingHeader> createState() => _SharedReadingHeaderState();
}

class _SharedReadingHeaderState extends ConsumerState<SharedReadingHeader> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSavingNickname = false;

  void _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isSavingNickname = true);
    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final myId = Supabase.instance.client.auth.currentUser!.id;
      
      // Check if nickname is taken
      final existing = await repository.getProfileByNickname(nickname);
      if (existing != null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
          );
        }
        return;
      }

      await repository.createOrUpdateProfile(myId, nickname);
      ref.invalidate(profileProvider(myId));
      ref.invalidate(myProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임이 설정되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingNickname = false);
    }
  }

  Widget _buildNicknameSetup() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.burgundy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '반가워요! 닉네임을 정해주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '친구들이 사용자님을 찾을 때 사용됩니다.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: '닉네임 입력 (예: 독서왕)',
              filled: true,
              fillColor: AppColors.ivory,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isSavingNickname 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                    icon: const Icon(Icons.check_circle, color: AppColors.burgundy),
                    onPressed: _saveNickname,
                  ),
            ),
            onSubmitted: (_) => _saveNickname(),
          ),
        ],
      ),
    );
  }

  void _searchFriend() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final results = await repository.searchProfilesByNickname(query);
      
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.ivory,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\'$query\' 검색 결과',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '일치하는 닉네임이 없습니다.',
                          style: TextStyle(color: AppColors.grey),
                        ),
                      ),
                    )
                  else
                    ...results.map((profile) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: profile.profileUrl != null ? NetworkImage(profile.profileUrl!) : null,
                          child: profile.profileUrl == null ? const Icon(Icons.person, color: AppColors.grey) : null,
                        ),
                        title: Text(profile.nickname ?? '알 수 없음'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final myId = Supabase.instance.client.auth.currentUser!.id;
                            await repository.sendFriendRequest(myId, profile.id);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('친구 요청을 보냈습니다.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.burgundy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('친구 요청'),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('검색 오류: $e')));
      }
    }
  }

  void _showFriendProfile(BuildContext context, Map<String, dynamic> friend) {
    // Determine the friend's profile info depending on whether user is requester or receiver
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final isRequester = friend['requester_id'] == myId;
    final profile = isRequester ? friend['receiver'] : friend['requester'];
    final friendId = isRequester ? friend['receiver_id'] : friend['requester_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: profile['profile_url'] != null ? NetworkImage(profile['profile_url']) : null,
                  child: profile['profile_url'] == null ? const Icon(Icons.person, size: 40, color: AppColors.grey) : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile['nickname'] ?? '이름 없음',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final repository = ref.read(supabaseRepositoryProvider);
                        final name = '함께 읽기'; // We can auto-generate a name
                        
                        await repository.createProject(
                          name: name,
                          ownerId: myId,
                          friendIds: [friendId],
                        );
                        
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('함께 읽기 초대권을 보냈습니다!')),
                          );
                          // Refresh projects
                          ref.invalidate(myProjectsProvider);
                        }
                      } catch (e) {
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('<함께 읽기>', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotifications() {
     showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.ivory,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
           return DraggableScrollableSheet(
             initialChildSize: 0.6,
             minChildSize: 0.3,
             maxChildSize: 0.9,
             expand: false,
             builder: (_, scrollController) {
               return Consumer(
                 builder: (context, ref, child) {
                   final reqAsync = ref.watch(pendingFriendRequestsProvider);
                   final notiAsync = ref.watch(notificationsProvider);
                   
                   return ListView(
                     controller: scrollController,
                     padding: const EdgeInsets.all(20),
                     children: [
                       const Text(
                         '알림',
                         style: TextStyle(
                           fontFamily: 'Pretendard',
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           color: AppColors.charcoal,
                         ),
                       ),
                       const SizedBox(height: 16),
                       // Friend Requests
                       reqAsync.when(
                         data: (reqs) {
                           if (reqs.isEmpty) return const SizedBox.shrink();
                           return Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('친구 요청', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.burgundy)),
                               ...reqs.map((req) {
                                 final profile = req['requester'];
                                 return ListTile(
                                   leading: const CircleAvatar(child: Icon(Icons.person)),
                                   title: Text('${profile['nickname']} 님의 친구 요청'),
                                   trailing: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       IconButton(
                                         icon: const Icon(Icons.check, color: AppColors.burgundy),
                                         onPressed: () async {
                                           final myId = Supabase.instance.client.auth.currentUser!.id;
                                           await ref.read(supabaseRepositoryProvider).acceptFriendRequest(req['id'], req['requester_id'], myId);
                                           ref.invalidate(pendingFriendRequestsProvider);
                                           ref.invalidate(friendsProvider);
                                         },
                                       ),
                                     ],
                                   ),
                                 );
                               }).toList(),
                               const Divider(),
                             ],
                           );
                         },
                         loading: () => const CircularProgressIndicator(),
                         error: (_, __) => const Text('Error'),
                       ),
                       // Other Notifications
                       notiAsync.when(
                         data: (notis) {
                           if (notis.isEmpty) {
                             return const Padding(
                               padding: EdgeInsets.all(20.0),
                               child: Text('새로운 알림이 없습니다.', style: TextStyle(color: AppColors.grey)),
                             );
                           }
                           return Column(
                             children: notis.map((noti) {
                               return ListTile(
                                 title: Text(noti.message ?? '알림'),
                                 subtitle: Text(
                                   noti.createdAt.toString().split('.')[0],
                                   style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
                                 ),
                                 leading: const Icon(Icons.notifications_active, color: AppColors.burgundy),
                                 tileColor: noti.isRead ? Colors.transparent : Colors.white,
                                 onTap: () {
                                    ref.read(supabaseRepositoryProvider).markNotificationAsRead(noti.id);
                                    ref.invalidate(notificationsProvider);
                                 },
                               );
                             }).toList(),
                           );
                         },
                         loading: () => const CircularProgressIndicator(),
                         error: (_, __) => const Text('Error'),
                       ),
                     ],
                   );
                 },
               );
             }
           );
        }
     );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final pendingReqsAsync = ref.watch(pendingFriendRequestsProvider);
    final notisAsync = ref.watch(notificationsProvider);
    
    return profileAsync.when(
      data: (profile) {
        if (profile == null || (profile.nickname?.isEmpty ?? true)) {
          return _buildNicknameSetup();
        }

        // Check if there are unread notifications or pending requests
        int badgeCount = 0;
        pendingReqsAsync.whenData((reqs) => badgeCount += reqs.length);
        notisAsync.whenData((notis) => badgeCount += notis.where((n) => !n.isRead).length);

        return Column(
          children: [
            // Top Row: Search Bar + Friends Icon + Notification Bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Search Bar (shortened)
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.burgundy.withOpacity(0.1), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.burgundy.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.burgundy, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: '닉네임으로 친구 추가',
                                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.grey.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _searchFriend(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Friends List Icon
                  _buildFriendsButton(),
                  
                  // Notification Bell
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: AppColors.charcoal, size: 28),
                        onPressed: _showNotifications,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.burgundy,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badgeCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // "책 함께 읽기" Start Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: _showCreateProjectSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.burgundy, AppColors.burgundy.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.burgundy.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        '책 함께 읽기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFriendsButton() {
    final friendsAsync = ref.watch(friendsProvider);
    
    return friendsAsync.when(
      data: (friends) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: AppColors.charcoal, size: 26),
              onPressed: () => _showFriendsList(friends),
            ),
            if (friends.isNotEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    friends.length.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const IconButton(
        icon: Icon(Icons.people_alt_outlined, color: AppColors.greyLight, size: 26),
        onPressed: null,
      ),
      error: (_, __) => const IconButton(
        icon: Icon(Icons.people_alt_outlined, color: AppColors.greyLight, size: 26),
        onPressed: null,
      ),
    );
  }

  void _showFriendsList(List<Map<String, dynamic>> friends) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 친구',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                if (friends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('아직 친구가 없습니다.\n닉네임 검색으로 친구를 추가해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ),
                  )
                else
                  ...friends.map((friend) {
                    final myId = Supabase.instance.client.auth.currentUser!.id;
                    final isRequester = friend['requester_id'] == myId;
                    final profile = isRequester ? friend['receiver'] : friend['requester'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: profile['profile_url'] != null ? NetworkImage(profile['profile_url']) : null,
                        child: profile['profile_url'] == null ? const Icon(Icons.person, color: AppColors.grey) : null,
                      ),
                      title: Text(
                        profile['nickname'] ?? '이름 없음',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateProjectSheet() {
    final friends = ref.read(friendsProvider).valueOrNull ?? [];
    final selectedFriendIds = <String>{};
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ivory,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '책 함께 읽기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '함께 읽을 친구를 선택하세요',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    
                    if (friends.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '친구가 없습니다.\n먼저 닉네임 검색으로 친구를 추가해주세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final myId = Supabase.instance.client.auth.currentUser!.id;
                            final isRequester = friend['requester_id'] == myId;
                            final profile = isRequester ? friend['receiver'] : friend['requester'];
                            final friendId = isRequester ? friend['receiver_id'] : friend['requester_id'];
                            final isSelected = selectedFriendIds.contains(friendId);
                            
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedFriendIds.remove(friendId);
                                  } else {
                                    selectedFriendIds.add(friendId);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.burgundy.withOpacity(0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.burgundy.withOpacity(0.3) : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.ivory,
                                      backgroundImage: profile['profile_url'] != null ? NetworkImage(profile['profile_url']) : null,
                                      child: profile['profile_url'] == null ? const Icon(Icons.person, color: AppColors.grey, size: 20) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        profile['nickname'] ?? '이름 없음',
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? AppColors.burgundy : AppColors.greyLight,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: selectedFriendIds.isEmpty ? null : () async {
                            try {
                              final myId = Supabase.instance.client.auth.currentUser!.id;
                              final repository = ref.read(supabaseRepositoryProvider);
                              
                              await repository.createProject(
                                name: '함께 읽기',
                                ownerId: myId,
                                friendIds: selectedFriendIds.toList(),
                              );
                              
                              ref.invalidate(myProjectsProvider);
                              ref.invalidate(myProjectsWithMembersProvider);
                              
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('함께 읽기 프로젝트가 시작되었습니다! 🎉')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('오류: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.burgundy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.greyLight.withOpacity(0.3),
                            disabledForegroundColor: AppColors.grey,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            selectedFriendIds.isEmpty
                                ? '친구를 선택해주세요'
                                : '${selectedFriendIds.length}명과 함께 읽기 시작',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
