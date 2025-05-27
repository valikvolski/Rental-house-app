import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'home_page.dart';
import 'welcome_page.dart';

class WelcomeFlow extends StatefulWidget {
  final AuthService authService;
  const WelcomeFlow({Key? key, required this.authService}) : super(key: key);

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  bool _wasLoggedIn = false;
  bool _explicitSignOut = false;

  void _handleSignOut() {
    setState(() {
      _explicitSignOut = true;
      _wasLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Ошибка авторизации:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          if (!_wasLoggedIn) {
            _wasLoggedIn = true;
            _explicitSignOut = false;
          }
          return HomePage(authService: widget.authService, onSignOut: _handleSignOut);
        }
        // WelcomePage показывается только если пользователь не был залогинен или явно вышел
        if (!_wasLoggedIn || _explicitSignOut) {
          return WelcomePage(
            onLogin: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AuthPage(
                    onSuccess: () => Navigator.of(context).pop(),
                    isLogin: true,
                    onBack: () => Navigator.of(context).pop(),
                    authService: widget.authService,
                  ),
                ),
              );
            },
            onRegister: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AuthPage(
                    onSuccess: () => Navigator.of(context).pop(),
                    isLogin: false,
                    onBack: () => Navigator.of(context).pop(),
                    authService: widget.authService,
                  ),
                ),
              );
            },
          );
        }
        // Если пользователь был залогинен, но не явно вышел — просто сообщение
        return Scaffold(
          body: Center(
            child: Text(
              'Вы вышли из аккаунта. Войдите снова для доступа к приложению.',
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
} 