import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // Navigation is handled by router redirect
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${_translateAuthError(e.toString())}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String error) {
    if (error.contains('invalid_credentials') || error.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (error.contains('over_email_send_rate_limit') || error.contains('rate limit')) {
      return '요청 횟수가 초과되었습니다. 잠시 후 다시 시도해주세요.';
    }
    if (error.contains('Email not confirmed')) {
      return '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요.';
    }
    return error.replaceAll('Exception: Login failed: ', '').replaceAll('AuthApiException(message: ', '').replaceAll(')', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Title
              Text(
                'Florence',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontFamily: 'Serif', // Use a serif font if available
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '나만의 독서 기록, 피렌체',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                    ),
              ),
              const SizedBox(height: 48),

              // Email Field
              NeumorphicContainer(
                depth: -2.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: '이메일',
                    border: InputBorder.none,
                    icon: Icon(Icons.email_outlined, color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              NeumorphicContainer(
                depth: -2.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '비밀번호',
                    border: InputBorder.none,
                    icon: Icon(Icons.lock_outline, color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              _isLoading
                  ? const Center(child: FlorenceLoader())
                  : NeumorphicButton(
                      onPressed: _login,
                      color: AppColors.burgundy,
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),

              // Sign Up Link
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text(
                  '계정이 없으신가요? 회원가입',
                  style: TextStyle(color: AppColors.burgundy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
