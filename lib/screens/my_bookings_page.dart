import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/listing_service.dart';
import '../models/house_model.dart';
import 'home_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'unauthenticated_profile_page.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsPage extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onSignOut;
  
  const MyBookingsPage({super.key, this.authService, this.onSignOut});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  int _currentIndex = 1; // Индекс для бронирований в нижней навигации
  final bookingService = BookingService();
  final listingService = ListingService();

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
        // Уже на этой странице
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
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedText(
          text: 'Мои бронирования',
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
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildBookingSkeleton(colors),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${snapshot.error}',
                style: GoogleFonts.montserrat(
                  color: colors.error,
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: colors.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'У вас пока нет бронирований',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Здесь будут отображаться все ваши активные и завершённые бронирования.',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return FutureBuilder<HouseModel?>(
                future: listingService.getListing(booking.houseId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildBookingSkeleton(colors);
                  }
                  final house = snapshot.data;
                  if (house == null) return const SizedBox.shrink();
                  return Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHouseImage(house, colors),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      house.title,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: colors.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatusChip(booking.status, colors),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: colors.onSurface.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    house.location,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDateTile('Заезд', booking.checkIn, colors.primary),
                                    Icon(Icons.arrow_forward, size: 20, color: colors.onSurface.withOpacity(0.4)),
                                    _buildDateTile('Выезд', booking.checkOut, colors.error),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Общая сумма',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colors.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      Text(
                                        '${booking.totalPrice.toStringAsFixed(2)} ₽',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (booking.status == 'pending')
                                    OutlinedButton.icon(
                                      icon: Icon(Icons.close, size: 18, color: colors.error),
                                      label: Text(
                                        'Отменить',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w500,
                                          color: colors.error,
                                        ),
                                      ),
                                      onPressed: () => _showCancelDialog(booking.id, colors),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: colors.error),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Брони'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Избранное'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildHouseImage(HouseModel house, ColorScheme colors) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
        ),
        child: house.images.isNotEmpty
            ? Image.network(
                house.images.first,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : Container(
                          color: colors.surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                },
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(colors),
              )
            : _buildImagePlaceholder(colors),
      ),
    );
  }

  Widget _buildStatusChip(String status, ColorScheme colors) {
    final statusData = _getStatusData(status, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusData.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusData.icon, size: 16, color: statusData.color),
          const SizedBox(width: 6),
          Text(
            statusData.text,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusData.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMM yyyy', 'ru').format(date),
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colors) {
    return Container(
      color: colors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 48,
          color: colors.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBookingSkeleton(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Shimmer.fromColors(
        baseColor: colors.surfaceVariant,
        highlightColor: colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Container(
                height: 20,
                width: 200,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 150,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, IconData icon, String text}) _getStatusData(String status, ColorScheme colors) {
    switch (status) {
      case 'pending':
        return (
          color: Colors.orange,
          icon: Icons.access_time,
          text: 'На рассмотрении'
        );
      case 'confirmed':
        return (
          color: Colors.green,
          icon: Icons.check_circle,
          text: 'Подтверждено'
        );
      case 'cancelled':
        return (
          color: colors.error,
          icon: Icons.cancel,
          text: 'Отменено'
        );
      case 'completed':
        return (
          color: Colors.blue,
          icon: Icons.done_all,
          text: 'Завершено'
        );
      default:
        return (
          color: colors.onSurface,
          icon: Icons.help_outline,
          text: 'Неизвестно'
        );
    }
  }

  void _showCancelDialog(String bookingId, ColorScheme colors) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Отмена бронирования',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text('Вы уверены что хотите отменить бронирование?',
            style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Нет', style: GoogleFonts.montserrat()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await bookingService.cancelBooking(bookingId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Бронирование отменено',
                          style: GoogleFonts.montserrat()),
                      backgroundColor: colors.error,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e',
                          style: GoogleFonts.montserrat()),
                      backgroundColor: colors.error,
                    ),
                  );
                }
              }
            },
            child: Text('Да, отменить', 
                style: GoogleFonts.montserrat(color: colors.error)),
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