import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── 로그아웃 ──
  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('로그아웃 실패: $e')));
      }
    }
  }

  // ── 회원 탈퇴 ──
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Delete user data from all tables
      final supabase = Supabase.instance.client;

      // Delete memos, user_books, profiles, friends, projects etc.
      await supabase.from('memos').delete().eq('user_id', user.id);
      await supabase.from('user_books').delete().eq('user_id', user.id);
      await supabase.from('shared_reading_members').delete().eq('user_id', user.id);
      await supabase.from('friends').delete().or('user_id.eq.${user.id},friend_id.eq.${user.id}');
      await supabase.from('friend_requests').delete().or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}');
      await supabase.from('profiles').delete().eq('id', user.id);

      // Sign out
      await supabase.auth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('탈퇴 처리 중 오류: $e')));
      }
    }
  }

  // ── 이메일 문의 ──
  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'audckswl@gmail.com',
      queryParameters: {
        'subject': '[Firenze] 문의사항',
        'body': '앱 버전: 1.0.0\n\n문의 내용을 작성해주세요.\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ── 앱 평점 남기기 ──
  Future<void> _launchRating() async {
    // App Store URL (앱 출시 후 실제 앱 ID로 교체)
    const storeUrl = 'https://apps.apple.com/app/id000000000?action=write-review';

    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '로그인 정보 없음';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '설정',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════
            // 섹션 1: 계정 및 데이터 관리
            // ═══════════════════════════════════════
            _buildSectionHeader(context, '계정'),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  title: '계정 정보',
                  subtitle: email,
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.logout,
                  title: '로그아웃',
                  color: AppColors.charcoal,
                  onTap: () => _showLogoutDialog(context),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.person_remove_outlined,
                  title: '회원 탈퇴',
                  color: Colors.red,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════
            // 섹션 2: 고객 지원 및 피드백
            // ═══════════════════════════════════════
            _buildSectionHeader(context, '지원'),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                _buildActionTile(
                  icon: Icons.mail_outline,
                  title: '1:1 문의하기',
                  subtitle: '오류 제보 및 기능 건의',
                  onTap: _launchEmail,
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.campaign_outlined,
                  title: '공지사항',
                  onTap: () {
                    // 공지사항 페이지 또는 URL로 이동
                    _showAnnouncementsDialog(context);
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.star_outline,
                  title: '평점 남기기',
                  subtitle: '앱이 마음에 드셨다면 별점을 남겨주세요',
                  onTap: _launchRating,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════
            // 섹션 3: 법적 고지
            // ═══════════════════════════════════════
            _buildSectionHeader(context, '약관 및 정책'),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                _buildActionTile(
                  icon: Icons.description_outlined,
                  title: '서비스 이용약관',
                  onTap: () => _showLegalPage(
                    context,
                    title: '서비스 이용약관',
                    content: _termsOfService,
                  ),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.shield_outlined,
                  title: '개인정보 처리방침',
                  onTap: () => _showLegalPage(
                    context,
                    title: '개인정보 처리방침',
                    content: _privacyPolicy,
                  ),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.code,
                  title: '오픈소스 라이선스',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Firenze',
                      applicationVersion: '1.0.0',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.menu_book,
                          size: 48,
                          color: AppColors.burgundy,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ═══════════════════════════════════════
            // 섹션 4: 앱 정보
            // ═══════════════════════════════════════
            _buildSectionHeader(context, '정보'),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline,
                  title: '앱 버전',
                  subtitle: '1.0.0',
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── 섹션 헤더 ──
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.grey,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  // ── 카드 컨테이너 ──
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── 정보 타일 (탭 불가) ──
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.burgundy, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.charcoal,
        ),
      ),
      trailing: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ── 액션 타일 (탭 가능) ──
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppColors.charcoal;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: c,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: AppColors.greyLight, size: 20),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  // ── 구분선 ──
  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Color(0xFFE8E8E8));
  }

  // ═══════════════════════════════════════════════════════
  // 다이얼로그들
  // ═══════════════════════════════════════════════════════

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.ivory,
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context);
            },
            child: const Text('확인', style: TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.ivory,
        title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '탈퇴 시 모든 데이터(독서 기록, 메모, 프로필 등)가 영구적으로 삭제됩니다.\n\n정말 탈퇴하시겠습니까?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmDialog(context),
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    Navigator.pop(context); // Close first dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.ivory,
        title: const Text('최종 확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
          '이 작업은 되돌릴 수 없습니다.\n\n삭제된 데이터는 복구할 수 없습니다. 정말 진행하시겠습니까?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context);
            },
            child: const Text('영구 삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.ivory,
        title: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.burgundy, size: 22),
            const SizedBox(width: 8),
            const Text('공지사항', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              _AnnouncementItem(
                date: '2026.03.26',
                title: '🎉 Firenze v1.0.0 출시!',
                body: '피렌체(Firenze)의 첫 번째 버전이 출시되었습니다. 독서의 즐거움을 함께 나눠보세요!',
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: AppColors.burgundy)),
          ),
        ],
      ),
    );
  }

  void _showLegalPage(BuildContext context, {required String title, required String content}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.ivory,
          appBar: AppBar(
            backgroundColor: AppColors.ivory,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black, fontSize: 16),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // 법적 문서 내용
  // ═══════════════════════════════════════════════════════
  static const String _termsOfService = '''
서비스 이용약관

제1조 (목적)
이 약관은 Firenze(이하 "앱")가 제공하는 서비스의 이용과 관련하여 필요한 사항을 규정함을 목적으로 합니다.

제2조 (서비스의 내용)
앱은 다음과 같은 서비스를 제공합니다.
1. 개인 독서 기록 관리 (책 등록, 읽기 상태 관리)
2. 독서 메모 저장 및 관리 (텍스트, 사진 메모)
3. 함께 읽기 프로젝트 (친구와 독서 공유)
4. 독서 통계 (선호 장르, 월별 독서량 분석)

제3조 (이용자의 의무)
이용자는 다음 행위를 하여서는 안 됩니다.
1. 타인의 개인정보를 도용하는 행위
2. 서비스를 이용하여 법령을 위반하는 행위
3. 앱의 운영을 방해하는 행위

제4조 (서비스 이용의 제한)
앱은 이용자가 본 약관을 위반하거나 서비스 운영에 지장을 초래하는 경우, 서비스 이용을 제한할 수 있습니다.

제5조 (면책조항)
1. 앱은 천재지변, 시스템 장애 등 불가항력적 사유로 서비스를 제공하지 못하는 경우 책임을 지지 않습니다.
2. 이용자의 귀책사유로 인한 서비스 이용 장애에 대해 책임을 지지 않습니다.

제6조 (약관의 변경)
앱은 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 앱 내 공지사항을 통해 고지합니다.

시행일: 2026년 3월 26일
''';

  static const String _privacyPolicy = '''
개인정보 처리방침

Firenze(이하 "앱")는 이용자의 개인정보를 중요시하며, 관련 법령을 준수합니다.

1. 수집하는 개인정보 항목
- 이메일 주소 (회원가입 및 로그인용)
- 프로필 이미지 (선택사항)
- 닉네임

2. 개인정보의 수집 및 이용 목적
- 서비스 제공 및 회원 관리
- 독서 기록 저장 및 통계 분석
- 서비스 개선 및 맞춤형 콘텐츠 제공

3. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시까지 보유
- 탈퇴 시 즉시 파기

4. 개인정보의 제3자 제공
앱은 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우는 예외로 합니다.
- 이용자가 사전에 동의한 경우
- 법령에 의해 요구되는 경우

5. 개인정보의 파기 절차 및 방법
회원 탈퇴 시 수집된 개인정보는 즉시 파기됩니다. 전자적 파일 형태의 정보는 복구 불가능한 방법으로 삭제합니다.

6. 개인정보 보호책임자
- 이름: 지명찬
- 이메일: audckswl@gmail.com

7. 개인정보 처리방침의 변경
이 개인정보 처리방침은 시행일로부터 적용되며, 변경 사항은 앱 내 공지를 통해 고지합니다.

시행일: 2026년 3월 26일
''';
}

// ── 공지사항 아이템 위젯 ──
class _AnnouncementItem extends StatelessWidget {
  final String date;
  final String title;
  final String body;

  const _AnnouncementItem({
    required this.date,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
