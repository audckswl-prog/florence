import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/florence_toast.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../social/providers/social_providers.dart';
import '../../library/providers/book_providers.dart';

// --- Shared Utility Functions for Social UI ---

void showSharedReadingFriendsList(
  BuildContext context,
  WidgetRef ref,
) {
  final searchFocusNode = ref.read(sharedReadingSearchFocusNodeProvider);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, child) {
          final friendsAsync = ref.watch(friendsProvider);

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 24,
              ),
              child: friendsAsync.when(
                loading: () => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 60),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (e, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 60),
                    Center(child: Text('오류: $e')),
                  ],
                ),
                data: (friends) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '내 친구 (${friends.length}명)',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            searchFocusNode.requestFocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.burgundy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            minimumSize: Size.zero,
                            elevation: 0,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '+친구 추가하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (friends.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            '아직 친구가 없습니다.\n닉네임 검색으로 친구를 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                      )
                    else
                      ...friends.map((friend) {
                        final myId = Supabase.instance.client.auth.currentUser!.id;
                        final isRequester = friend['requester_id'] == myId;
                        final profile = isRequester
                            ? friend['receiver']
                            : friend['requester'];
                        if (profile == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: profile['profile_url'] != null
                                    ? ClipOval(
                                        child: Image.network(
                                          profile['profile_url'],
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: AppColors.grey,
                                        size: 28,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  profile['nickname'] ?? '이름 없음',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showSharedReadingNotifications(BuildContext context, WidgetRef ref) {
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
                          const Text(
                            '친구 요청',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.burgundy,
                            ),
                          ),
                          ...reqs.map((req) {
                            final profile = req['requester'];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text('${profile['nickname']} 님의 친구 요청'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: AppColors.burgundy,
                                    ),
                                    onPressed: () async {
                                      final myId = Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser!
                                          .id;
                                      await ref
                                          .read(supabaseRepositoryProvider)
                                          .acceptFriendRequest(
                                            req['id'],
                                            req['requester_id'],
                                            myId,
                                          );
                                      ref.invalidate(
                                        pendingFriendRequestsProvider,
                                      );
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
                          child: Text(
                            '새로운 알림이 없습니다.',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: notis.map((noti) {
                          final nick = noti.senderNickname ?? '알 수 없음';
                          String displayMessage;
                          switch (noti.type) {
                            case 'friend_request':
                              displayMessage = '$nick님이 친구 요청을 보냈습니다.';
                              break;
                            case 'friend_accept':
                              displayMessage = '$nick님과 친구가 되었습니다!';
                              break;
                            case 'project_invite':
                              displayMessage = '$nick님의 함께 읽기에 초대되었습니다!';
                              break;
                            case 'project_started':
                              displayMessage =
                                  '함께 읽기가 시작되었습니다! 2주 안에 완독에 도전하세요.';
                              break;
                            case 'project_success':
                              displayMessage = '프로젝트 성공! 독서 티켓이 발급되었습니다.';
                              break;
                            default:
                              displayMessage = noti.message ?? '알림';
                          }
                          IconData icon;
                          switch (noti.type) {
                            case 'friend_request':
                            case 'friend_accept':
                              icon = Icons.people_alt_outlined;
                              break;
                            case 'project_invite':
                            case 'project_started':
                              icon = Icons.menu_book_rounded;
                              break;
                            case 'project_success':
                              icon = Icons.emoji_events_outlined;
                              break;
                            default:
                              icon = Icons.notifications_active;
                          }
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            leading: Icon(
                              icon,
                              color: AppColors.burgundy,
                              size: 22,
                            ),
                            title: Text(
                              displayMessage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: noti.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: AppColors.charcoal,
                              ),
                            ),
                            subtitle: Text(
                              noti.createdAt.toString().split('.')[0],
                              style: const TextStyle(
                                color: AppColors.greyLight,
                                fontSize: 11,
                              ),
                            ),
                            tileColor: noti.isRead
                                ? Colors.transparent
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () {
                              ref
                                  .read(supabaseRepositoryProvider)
                                  .markNotificationAsRead(noti.id);
                              ref.invalidate(notificationsProvider);
                              Navigator.pop(context);
                              if (noti.type == 'project_invite' &&
                                  noti.relatedId != null) {
                                _showAcceptDeclineDialog(
                                  context,
                                  ref,
                                  noti.relatedId!,
                                );
                              } else if ((noti.type == 'project_started' ||
                                      noti.type == 'project_success') &&
                                  noti.relatedId != null) {
                                context.push(
                                  '/home/social/detail/${noti.relatedId}',
                                );
                              } else if (noti.type == 'friend_request' ||
                                  noti.type == 'friend_accept') {
                                showSharedReadingFriendsList(
                                  context,
                                  ref,
                                );
                              }
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
        },
      );
    },
  );
}

void showSharedReadingCreateProjectSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.ivory,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final selectedFriendIds = <String>{};
      return Consumer(
        builder: (context, ref, child) {
          final friendsAsync = ref.watch(friendsProvider);
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
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
                      friendsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('오류: $e')),
                        ),
                        data: (friends) {
                          if (friends.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  '아직 친구가 없습니다.\n먼저 친구를 추가해주세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.grey),
                                ),
                              ),
                            );
                          }
                          return Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                final friend = friends[index];
                                final myId = Supabase
                                    .instance.client.auth.currentUser!.id;
                                final isRequester =
                                    friend['requester_id'] == myId;
                                final profile = isRequester
                                    ? friend['receiver']
                                    : friend['requester'];
                                final friendId = isRequester
                                    ? friend['receiver_id']
                                    : friend['requester_id'];
                                if (profile == null) {
                                  return const SizedBox.shrink();
                                }
                                final isSelected =
                                    selectedFriendIds.contains(friendId);

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    backgroundImage: profile['profile_url'] !=
                                            null
                                        ? NetworkImage(profile['profile_url'])
                                        : null,
                                    child: profile['profile_url'] == null
                                        ? const Icon(
                                            Icons.person,
                                            color: AppColors.grey,
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    profile['nickname'] ?? '이름 없음',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.burgundy,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (val == true) {
                                          selectedFriendIds.add(friendId);
                                        } else {
                                          selectedFriendIds.remove(friendId);
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setModalState(() {
                                      if (isSelected) {
                                        selectedFriendIds.remove(friendId);
                                      } else {
                                        selectedFriendIds.add(friendId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: selectedFriendIds.isEmpty
                              ? null
                              : () async {
                                  try {
                                    final repository = ref.read(
                                      supabaseRepositoryProvider,
                                    );
                                    final myId = Supabase
                                        .instance.client.auth.currentUser!.id;

                                    await repository.createProject(
                                      name: '함께 읽기',
                                      ownerId: myId,
                                      friendIds: selectedFriendIds.toList(),
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('함께 읽기 초대권을 보냈습니다!'),
                                        ),
                                      );
                                      ref.invalidate(myProjectsProvider);
                                      ref.invalidate(
                                          myProjectsWithMembersProvider);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('오류: $e')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.burgundy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.greyLight.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '초대장 보내기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

// --- Main Widgets for Shared Reading Header ---

class SharedReadingAppBarTitle extends ConsumerStatefulWidget {
  const SharedReadingAppBarTitle({super.key});

  @override
  ConsumerState<SharedReadingAppBarTitle> createState() =>
      _SharedReadingAppBarTitleState();
}

class _SharedReadingAppBarTitleState
    extends ConsumerState<SharedReadingAppBarTitle> {
  final TextEditingController _searchController = TextEditingController();

  void _searchFriend() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final myId = Supabase.instance.client.auth.currentUser!.id;
      final results = await repository.searchProfilesByNickname(query);

      if (!mounted) return;

      // 각 프로필의 기존 friendship 상태 조회
      final statusMap = <String, String?>{};
      for (final profile in results) {
        statusMap[profile.id] = await repository.checkExistingFriendship(myId, profile.id);
      }

      if (!mounted) return;

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
                          final existingStatus = statusMap[profile.id];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: profile.profileUrl != null
                                  ? NetworkImage(profile.profileUrl!)
                                  : null,
                              child: profile.profileUrl == null
                                  ? const Icon(Icons.person, color: AppColors.grey)
                                  : null,
                            ),
                            title: Text(profile.nickname ?? '알 수 없음'),
                            trailing: _buildFriendActionButton(
                              ctx: ctx,
                              repository: repository,
                              myId: myId,
                              profileId: profile.id,
                              existingStatus: existingStatus,
                              statusMap: statusMap,
                              setModalState: setModalState,
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('검색 오류: $e')));
      }
    }
  }

  Widget _buildFriendActionButton({
    required BuildContext ctx,
    required SupabaseRepository repository,
    required String myId,
    required String profileId,
    required String? existingStatus,
    required Map<String, String?> statusMap,
    required void Function(void Function()) setModalState,
  }) {
    if (existingStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.greyLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '이미 친구',
          style: TextStyle(color: AppColors.grey, fontSize: 13),
        ),
      );
    }
    if (existingStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.greyLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '요청됨',
          style: TextStyle(color: AppColors.grey, fontSize: 13),
        ),
      );
    }
    return ElevatedButton(
      onPressed: () async {
        try {
          await repository.sendFriendRequest(myId, profileId);
          // provider 갱신
          ref.invalidate(pendingFriendRequestsProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(friendsProvider);
          // 상태 업데이트
          setModalState(() {
            statusMap[profileId] = 'pending';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('친구 요청을 보냈습니다.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('친구 요청 실패: ${e.toString().replaceAll('Exception: ', '')}')),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.burgundy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text('친구 요청'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReqsAsync = ref.watch(pendingFriendRequestsProvider);
    final notisAsync = ref.watch(notificationsProvider);
    final searchFocusNode = ref.watch(sharedReadingSearchFocusNodeProvider);

    int badgeCount = 0;
    pendingReqsAsync.whenData((reqs) => badgeCount += reqs.length);
    notisAsync.whenData(
      (notis) => badgeCount += notis.where((n) => !n.isRead).length,
    );

    return Row(
      children: [
        // Search Bar (shortened)
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.burgundy.withOpacity(0.1),
                width: 1.0,
              ),
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
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '닉네임으로 친구 추가',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
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
        IconButton(
          icon: const Icon(
            Icons.people_alt_outlined,
            color: AppColors.charcoal,
            size: 26,
          ),
          onPressed: () {
            showSharedReadingFriendsList(context, ref);
          },
        ),

        // Notification Bell
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.charcoal,
                size: 28,
              ),
              onPressed: () => showSharedReadingNotifications(context, ref),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SharedReadingHeader extends ConsumerStatefulWidget {
  const SharedReadingHeader({super.key});

  @override
  ConsumerState<SharedReadingHeader> createState() =>
      _SharedReadingHeaderState();
}

class _SharedReadingHeaderState extends ConsumerState<SharedReadingHeader> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSavingNickname = false;

  void _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isSavingNickname = true);
    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final myId = Supabase.instance.client.auth.currentUser!.id;

      final existing = await repository.getProfileByNickname(nickname);
      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')));
        }
        return;
      }

      await repository.createOrUpdateProfile(myId, nickname);
      ref.invalidate(profileProvider(myId));
      ref.invalidate(myProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('닉네임이 설정되었습니다!')));
      }
    } catch (e) {
      if (mounted) {}
    } finally {
      if (mounted) setState(() => _isSavingNickname = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null || (profile.nickname?.isEmpty ?? true)) {
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: AppColors.burgundy,
                            ),
                            onPressed: _saveNickname,
                          ),
                  ),
                  onSubmitted: (_) => _saveNickname(),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onTap: () => showSharedReadingCreateProjectSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.burgundy,
                    AppColors.burgundy.withOpacity(0.85),
                  ],
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
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

void _showAcceptDeclineDialog(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(
          '함께 읽기 초대',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pretendard'),
        ),
        content: const Text('독서 모임 초대를 수락하시겠습니까?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('거절', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final myId = Supabase.instance.client.auth.currentUser!.id;
                await ref.read(supabaseRepositoryProvider).joinProject(projectId, myId);
                ref.invalidate(myProjectsWithMembersProvider);
                if (context.mounted) {
                  context.push('/home/social/detail/$projectId');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('수락 중 오류가 발생했습니다: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('수락'),
          ),
        ],
      );
    },
  );
}
