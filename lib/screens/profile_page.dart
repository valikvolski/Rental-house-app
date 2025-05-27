import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'edit_profile_page.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_listing_page.dart';
import 'unauthenticated_profile_page.dart';
import 'admin/admin_panel_page.dart';
import 'my_listings_page.dart';
import 'favorites_page.dart';
import '../services/listing_service.dart';
import '../models/house_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner_bookings_page.dart';
import 'my_bookings_page.dart';
import 'landlord/rental_analytics_page.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final VoidCallback? onSignOut;
  
  const ProfilePage({super.key, required this.authService, this.onSignOut});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await widget.authService.signOut();
      widget.onSignOut?.call();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UnauthenticatedProfilePage(authService: widget.authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || _isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Загрузка профиля...', style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final displayName = data?['displayName'] ?? user.displayName ?? 'Без имени';
        final email = data?['email'] ?? user.email ?? 'Нет email';
        final phone = data?['phoneNumber'] ?? '';
        final role = data?['role'] ?? 'user';
        final photoUrl = data?['photoUrl'] ?? user.photoURL;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Профиль',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Аватар и имя пользователя
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl != null && photoUrl != ''
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl == '')
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        role == 'admin'
                            ? 'Администратор'
                            : role == 'landlord'
                                ? 'Арендодатель'
                                : 'Арендатор',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Список настроек
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Личные данные',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(
                                authService: widget.authService,
                                initialName: displayName,
                                initialEmail: email,
                                initialPhone: phone,
                                initialRole: role,
                                initialPhotoUrl: photoUrl,
                              ),
                            ),
                          );
                          if (result != null && result is Map<String, String>) {
                            setState(() {
                              // Здесь можно обновить локальные данные профиля
                            });
                          }
                        },
                      ),

                      if (role == 'admin')
                        _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Админ-панель',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminPanelPage(),
                              ),
                            );
                          },
                        ),
                      if (role == 'landlord' || role == 'admin')
                        _buildMenuItem(
                          icon: Icons.list_alt,
                          title: 'Мои объявления',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyListingsPage(),
                              ),
                            );
                          },
                        ),
                      if (role == 'landlord' || role == 'admin')
                        _buildMenuItem(
                          icon: Icons.calendar_today,
                          title: 'Заявки на бронирование',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OwnerBookingsPage(),
                              ),
                            );
                          },
                        ),
                      if (role == 'landlord' || role == 'admin')
                        _buildMenuItem(
                          icon: Icons.analytics_outlined,
                          title: 'Аналитика аренды',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RentalAnalyticsPage(),
                              ),
                            );
                          },
                        ),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Выйти',
                        onTap: () async {
                          await _signOut();
                        },
                        isLogout: true,
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                currentIndex: 3,
                onTap: (index) {
                  if (index == 3) return; // Уже на странице профиля
                  switch (index) {
                    case 0: // Главная
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            authService: widget.authService,
                            onSignOut: widget.onSignOut,
                          ),
                        ),
                      );
                      break;
                    case 1: // Мои бронирования
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyBookingsPage(
                            authService: widget.authService,
                            onSignOut: widget.onSignOut,
                          ),
                        ),
                      );
                      break;
                    case 2: // Избранное
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FavoritesPage(
                            authService: widget.authService,
                            onSignOut: widget.onSignOut,
                          ),
                        ),
                      );
                      break;
                  }
                },
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
                unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey[600],
                items: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Главная'),
                  _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Брони'),
                  _buildNavItem(Icons.favorite_outline, Icons.favorite_rounded, 'Избранное'),
                  _buildNavItem(Icons.person_outline, Icons.person_rounded, 'Профиль'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: isLogout
          ? null
          : const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
      onTap: onTap,
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData outline, IconData filled, String label) {
    return BottomNavigationBarItem(
      icon: Icon(outline, size: 26),
      activeIcon: Icon(filled, size: 26),
      label: label,
    );
  }
} 