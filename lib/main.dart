import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/home_page.dart';
import 'screens/auth_page.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Проверяем инициализацию Firebase Storage
    final storage = FirebaseStorage.instance;
    print('DEBUG: Firebase Storage инициализирован');
    
    final authService = AuthService();
    // Делаем полноэкранный режим
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // светлые иконки для лучшей видимости на черном фоне
      ),
    );
    runApp(MyApp(authService: authService));
  } catch (e) {
    print('ERROR: Ошибка инициализации Firebase: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  const MyApp({
    super.key,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomePage(authService: authService);
          }
          return AuthPage(
            onSuccess: () {},
            isLogin: true,
            onBack: () {},
            authService: authService,
          );
        },
      ),
    );
  }
}
