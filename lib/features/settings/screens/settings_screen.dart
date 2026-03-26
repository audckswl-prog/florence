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
  // 법적 문서 내용 (상용 서비스 규격 및 개발자 리스크 방어 포함)
  // ═══════════════════════════════════════════════════════
  static const String _termsOfService = '''
서비스 이용약관

제1조 (목적)
본 약관은 "Firenze"(이하 "앱")가 제공하는 독서 기록 및 공유 서비스(이하 "서비스")를 이용함에 있어, 이용자와 서비스 제공자(이하 "회사" 또는 "개발자") 간의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"라 함은 이용자가 독서 기록을 생성, 관리하고 친구와 공유할 수 있도록 제공되는 모든 기능을 의미합니다.
2. "이용자"란 본 약관에 동의하고 서비스를 이용하는 회원을 의미합니다.
3. "콘텐츠"란 이용자가 서비스 내에 게시한 사진, 글, 메모, 정보 등의 자료를 의미합니다.

제3조 (서비스의 제공 및 변경)
1. 서비스는 연중무휴, 1일 24시간 제공을 원칙으로 합니다.
2. 개발자는 서비스의 운영상, 기술상 필요에 따라 제공하고 있는 서비스의 전부 또는 일부를 변경하거나 중단할 수 있습니다.
3. 서비스는 기본적으로 무료로 제공되며, 이는 개발자의 판단에 따라 유료 기능 도입 등 변경될 수 있습니다.

제4조 (이용자의 의무 및 게시물 관리)
1. 이용자는 서비스를 이용할 때 다음 각 호의 행위를 하여서는 안 됩니다.
   - 타인의 정보 도용 또는 허위 사실 등록
   - 저작권 등 제3자의 지식재산권 침해
   - 공공질서 및 미풍양속에 반하는 유해한 콘텐츠 게시
   - 서비스의 안정적 운영을 방해할 수 있는 코드 및 해킹 시도
2. 서비스 내 게시된 "콘텐츠"에 대한 저작권은 작성자 본인에게 있으며, 게시물로 인해 발생하는 모든 법적 책임은 해당 이용자에게 귀속됩니다.
3. 앱 내에서 촬영하거나 업로드하는 사진은 저작권 및 초상권 등 관련 법령을 준수해야 합니다.

제5조 (게시물의 삭제 및 이용 제한)
개발자는 제4조의 의무를 위반하거나 부적절하다고 판단되는 콘텐츠에 대해 사전 통지 없이 삭제하거나 이용자의 서비스 이용을 제한 또는 계정을 삭제할 수 있습니다.

제6조 (저작권의 귀속 및 이용제한)
1. 앱이 작성한 저적물에 대한 저작권 및 기타 지식재산권은 앱에게 귀속됩니다.
2. 이용자는 서비스를 이용함으로써 얻은 정보 중 앱에게 지식재산권이 귀속된 정보를 앱의 사전 승낙 없이 복제, 송신, 출판, 배포, 방송 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 하여서는 안됩니다.

제7조 (면책 및 책임의 제한)
1. 개발자는 천재지변, 서버 장애, 통신망 장애 등 불가항력적인 사유로 인하여 서비스를 제공할 수 없는 경우에는 책임이 면제됩니다.
2. 개발자는 이용자가 서비스를 통해 게재한 정보, 자료, 사실의 신뢰도 및 정확성 등에 대해서는 책임을 지지 않습니다.
3. 개발자는 이용자 간 혹은 이용자와 제3자 상호 간에 서비스를 매개로 하여 발생한 분쟁에 대해 개입할 의무가 없으며, 이로 인한 손해를 배상할 책임도 없습니다.
4. 서비스 이용 중 발생한 데이터 유실, 기기 장애 등에 대해 개발자는 고의 또는 중대한 과실이 없는 한 책임을 지지 않습니다.

제8조 (분쟁의 해결)
서비스 이용과 관련하여 발생한 분쟁에 대해서는 대한민국 법령을 준거법으로 하며, 관할 법원은 민사소송법에 따릅니다.

시행일: 2026년 3월 26일
''';

  static const String _privacyPolicy = '''
개인정보 처리방침

Firenze(이하 "앱")는 이용자의 개인정보를 중요시하며, '개인정보 보호법' 및 '정보통신망 이용촉진 및 정보보호 등에 관한 법률' 등 관련 법령을 준수합니다.

제1조 (수집하는 개인정보 항목 및 수집방법)
앱은 서비스 제공을 위해 최소한의 개인정보를 수집하고 있습니다.
1. 수집 항목
   - 필수: 이메일 주소, 비밀번호(암호화), 닉네임
   - 선택: 프로필 이미지
   - 서비스 이용 기록: 독서 목록, 독서 상태, 작성 메모(텍스트 및 사진), 친구 목록
   - 자동 생성 항목: 기기 식별번호(UUID), 모델명, OS 버전, 접속 로그, 서비스 이용 통계
2. 수집 방법: 회원 가입 및 서비스 이용 과정에서 이용자가 직접 입력하거나 기기에서 자동 생성

제2조 (개인정보의 이용 목적)
1. 서비스 제공 및 본인 식별: 회원 가입 의사 확인, 서비스 이용 권한 부여
2. 기록 관리 및 통계: 독서 노트 저장, 통계 그래프 생성, 데이터 백업
3. 소셜 기능 서비스: 친구 추가 및 함께 읽기 공유 기능 제공
4. 고객 지원: 문의사항 처리, 공지사항 전달, 앱의 기능 개선 및 안정화

제3조 (기기 접근 권한의 이용 및 거부)
앱은 특정 기능을 제공하기 위해 아래의 기기 권한을 사용합니다.
1. 사진첩 및 카메라 접근: 프로필 설정 및 도서 정보 촬영, 메모 내 사진 첨부 목적
2. 해당 권한은 사용자가 기능을 이용할 시점에 명시적으로 동의를 요청하며, 거부하더라도 해당 기능을 제외한 기본 서비스는 이용 가능합니다.

제4조 (개인정보의 보유 및 이용기간)
이용자의 개인정보는 원칙적으로 회원 탈퇴 시 즉시 파기합니다. 단, 관련 법령(상법, 전자상거래법 등)에 따라 보존할 필요가 있는 경우 해당 법령이 정한 기간 동안 보관합니다.

제5조 (개인정보의 파기절차 및 방법)
1. 파기절차: 이용자가 회원 탈퇴를 요청할 경우 목적이 달성된 개인정보를 즉시 영구 삭제합니다.
2. 파기방법: 전자적 파일 형태로 저장된 개인정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제합니다.

제6조 (이용자의 권리와 그 행사방법)
1. 이용자는 언제든지 자신의 개인정보를 열람, 수정하거나 서비스 내 '회원 탈퇴' 기능을 통해 개인정보의 파기를 요청할 수 있습니다.
2. 이용자가 개인정보의 오류에 대한 정정을 요청한 경우, 정정을 완료하기 전까지 해당 개인정보를 이용 또는 제공하지 않습니다.

제7조 (개인정보의 안정성 확보 조치)
앱은 개인정보를 보호하기 위해 다음과 같은 대책을 강구하고 있습니다.
1. 비밀번호의 암호화 저장 및 전송 구간 보안(SSL/TLS) 적용
2. 해킹 등에 대비한 데이터베이스 보호 조치

제8조 (개인정보 보호책임자 및 상담창구)
서비스 이용 중 발생하는 모든 개인정보 관련 문의는 아래의 보호책임자에게 문의하실 수 있습니다.
- 성명: 지명찬
- 이메일: audckswl@gmail.com

제9조 (개인정보 처리방침의 변경)
본 방침은 시행일로부터 적용되며, 법령 및 서비스 변경에 따른 추가, 삭제 등이 있는 경우 앱 내 공지를 통해 사전 고지합니다.

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
