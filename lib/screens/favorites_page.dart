import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/favorite_service.dart';
import '../models/house_model.dart';
import 'house_details_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'unauthenticated_profile_page.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_bookings_page.dart';

class FavoritesPage extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onSignOut;
  
  const FavoritesPage({super.key, this.authService, this.onSignOut});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int _currentIndex = 2; // Индекс для избранного в нижней навигации

  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return;
    
    switch (index) {
      case 0: // Главная
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              authService: widget.authService!,
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
        // Уже на этой странице
        break;
      case 3: // Профиль
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                authService: widget.authService!,
                onSignOut: widget.onSignOut,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnauthenticatedProfilePage(
                authService: widget.authService!,
              ),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: AnimatedText(
          text: 'Избранное',
          duration: const Duration(milliseconds: 500),
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50.withOpacity(0.2),
              Colors.blue.shade50.withOpacity(0.1),
            ],
          ),
        ),
        child: StreamBuilder<List<HouseModel>>(
          stream: FavoriteService().getUserFavorites(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final favorites = snapshot.data ?? [];
            if (favorites.isEmpty) {
              return _EmptyFavoritesState(colors: colors);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final house = favorites[index];
                return _FavoriteCard(
                  house: house,
                onRemove: () async {
                    await FavoriteService().removeFavorite(house.id);
                    if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Удалено из избранного'),
                          behavior: SnackBarBehavior.floating,
                        ),
                  );
                    }
                },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Мои бронирования',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final HouseModel house;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.house, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final img = house.images.isNotEmpty ? house.images.first : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseDetailsPage(house: house),
          ),
        );
      },
          borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: img != null && img.startsWith('http')
                        ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.error_outline, size: 40),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(Icons.home, size: 40),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: onRemove,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 4,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${house.price.toStringAsFixed(0)} ₽',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    house.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          house.location,
                          style: GoogleFonts.montserrat(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFeature(
                        Icons.bed,
                        '${house.bedrooms}',
                        'спален',
                      ),
                      const SizedBox(width: 16),
                      _buildFeature(
                        Icons.bathtub,
                        '${house.bathrooms}',
                        'ванных',
                      ),
                      const SizedBox(width: 16),
                      _buildFeature(
                        Icons.square_foot,
                        '${house.area}',
                        'м²',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: GoogleFonts.montserrat(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  final ColorScheme colors;
  const _EmptyFavoritesState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.deepPurple.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'У вас пока нет избранных объявлений',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
            'Добавляйте понравившиеся объекты в избранное, чтобы быстро находить их позже.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedText extends StatelessWidget {
  final String text;
  final Duration duration;
  final TextStyle style;

  const AnimatedText({
    super.key,
    required this.text,
    required this.duration,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(text, style: style),
    );
  }
} 