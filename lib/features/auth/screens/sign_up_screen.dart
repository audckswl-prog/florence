import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../providers/auth_providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인 화면으로 이동합니다.')),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 실패: ${_translateAuthError(e.toString())}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String error) {
    if (error.contains('over_email_send_rate_limit') || error.contains('rate limit')) {
      return '이메일 전송 횟수가 초과되었습니다. 잠시 후 다시 시도해주세요.';
    }
    if (error.contains('User already registered') || error.contains('already been registered')) {
      return '이미 가입된 이메일 주소입니다.';
    }
    if (error.contains('invalid_credentials') || error.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (error.contains('Password should be at least')) {
      return '비밀번호는 6자 이상이어야 합니다.';
    }
    if (error.contains('Unable to validate email')) {
      return '올바른 이메일 주소를 입력해주세요.';
    }
    return error.replaceAll('Exception: Sign up failed: ', '').replaceAll('AuthApiException(message: ', '').replaceAll(')', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '회원가입',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),

              // Email
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

              // Password
              NeumorphicContainer(
                depth: -2.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '비밀번호 (6자 이상)',
                    border: InputBorder.none,
                    icon: Icon(Icons.lock_outline, color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              NeumorphicContainer(
                depth: -2.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: '비밀번호 확인',
                    border: InputBorder.none,
                    icon: Icon(Icons.check_circle_outline, color: AppColors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              _isLoading
                  ? const Center(child: FlorenceLoader())
                  : NeumorphicButton(
                      onPressed: _signUp,
                      color: AppColors.burgundy,
                      child: const Text(
                        '가입하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
