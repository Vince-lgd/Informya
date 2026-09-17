import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tappable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> result;

      if (_isRegister) {
        result = await ApiService.register(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        result = await ApiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result.containsKey('access_token')) {
        await ApiService.saveToken(result['access_token']);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/feed');
        }
      } else {
        setState(() {
          _error = result['detail']?.toString() ?? 'Une erreur est survenue';
        });
      }
    } catch (e) {
      setState(() => _error = 'Erreur de connexion au serveur');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(220, AppColors.circle1(context)),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: _blurCircle(180, AppColors.circle2(context)),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _blurCircle(160, AppColors.circle3(context)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),

                  // Titre
                  Text(
                    _isRegister ? 'Créer un\ncompte' : 'Bon\nretour',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRegister
                        ? 'Rejoins Informya'
                        : 'Content de te revoir sur Informya',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Formulaire
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.glassFill(context),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.glassBorder(context),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isRegister) ...[
                                _buildField(
                                  controller: _usernameController,
                                  hint: 'Nom d\'utilisateur',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 14),
                              ],
                              _buildField(
                                controller: _emailController,
                                hint: 'Email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _passwordController,
                                hint: 'Mot de passe',
                                icon: Icons.lock_outline,
                                obscureText: true,
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFB3261E),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFB3261E),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton principal
                  Tappable(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.glassFill(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.glassBorder(context),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? CupertinoActivityIndicator(
                                      color: AppColors.textPrimary(context),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'Créer mon compte'
                                          : 'Se connecter',
                                      style: TextStyle(
                                        color: AppColors.textPrimary(context),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bascule login / register
                  Center(
                    child: Tappable(
                      onTap: () => setState(() {
                        _isRegister = !_isRegister;
                        _error = null;
                      }),
                      child: RichText(
                        text: TextSpan(
                          text: _isRegister
                              ? 'Déjà un compte ? '
                              : 'Pas encore de compte ? ',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 15,
                          ),
                          children: [
                            TextSpan(
                              text: 'Clique ici',
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill(context).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.glassBorder(context).withValues(alpha: 0.6),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            cursorColor: AppColors.textPrimary(context),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: AppColors.icon(context), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
