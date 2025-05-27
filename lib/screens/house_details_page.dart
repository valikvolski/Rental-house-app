import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/house_model.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/report_dialog.dart';
import 'edit_listing_page.dart';
import '../services/favorite_service.dart';
import '../services/auth_service.dart';
import '../widgets/booking_dialog.dart';

class HouseDetailsPage extends StatefulWidget {
  final HouseModel house;
  const HouseDetailsPage({super.key, required this.house});

  @override
  State<HouseDetailsPage> createState() => _HouseDetailsPageState();
}

class _HouseDetailsPageState extends State<HouseDetailsPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _favoriteLoading = false;
  final _userService = UserService();
  Map<String, dynamic>? _ownerInfo;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _loadOwnerInfo();
  }

  Future<void> _loadOwnerInfo() async {
    try {
      final ownerInfo = await _userService.getUserInfo(widget.house.ownerId);
      if (mounted) {
        setState(() => _ownerInfo = ownerInfo);
      }
    } catch (e) {
      print('Error loading owner info: $e');
    }
  }

  Future<void> _checkFavorite() async {
    final fav = await FavoriteService().isFavorite(widget.house.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;
    setState(() => _favoriteLoading = true);
    try {
      if (_isFavorite) {
        await FavoriteService().removeFavorite(widget.house.id);
        if (mounted) setState(() => _isFavorite = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено из избранного')),
        );
      } else {
        await FavoriteService().addFavorite(widget.house.id);
        if (mounted) setState(() => _isFavorite = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Добавлено в избранное')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && user.uid == widget.house.ownerId;

    // Сохраняем внешний контекст для SnackBar
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.house.images.isNotEmpty)
                    PageView.builder(
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemCount: widget.house.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          widget.house.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('ERROR: Ошибка загрузки изображения: $error');
                            return Container(
                              color: colors.surfaceVariant,
                              child: const Center(
                                child: Icon(Icons.error_outline, size: 60, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      },
                    )
                  else
                    Container(
                      color: colors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.home, size: 100, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.house.images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? colors.primary
                                  : colors.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditListingPage(house: widget.house),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Удалить объявление?'),
                        content: const Text('Это действие нельзя отменить.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await ListingService().deleteListing(widget.house.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Объявление удалено')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ]
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: colors.primary),
                          const SizedBox(width: 8),
                  Text(
                            _formatDate(widget.house.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                    widget.house.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade800,
                    ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.house.status == 'active'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.house.status == 'active' ? 'Активно' : 'На модерации',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: widget.house.status == 'active'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: colors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.house.location,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFeatureChip(
                        icon: Icons.king_bed,
                        label: '${widget.house.bedrooms} спален',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureChip(
                        icon: Icons.bathtub,
                        label: '${widget.house.bathrooms} ванных',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureChip(
                        icon: Icons.square_foot,
                        label: '${widget.house.area} м²',
                      ),
                    ],
                  ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                  ),
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                              Expanded(
                                child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Цена',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.house.price.toStringAsFixed(0)} ₽',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Описание',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.house.description,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_ownerInfo != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _ownerInfo!['photoUrl'] != null && _ownerInfo!['photoUrl'] != ''
                                  ? NetworkImage(_ownerInfo!['photoUrl'])
                                  : null,
                              child: (_ownerInfo!['photoUrl'] == null || _ownerInfo!['photoUrl'] == '')
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ownerInfo!['displayName'] ?? 'Без имени',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _ownerInfo!['email'] ?? 'Нет email',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.contact_page, color: Colors.deepPurple, size: 28),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Контактная информация',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundImage: _ownerInfo!['photoUrl'] != null && _ownerInfo!['photoUrl'] != ''
                                                ? NetworkImage(_ownerInfo!['photoUrl'])
                                                : null,
                                            child: (_ownerInfo!['photoUrl'] == null || _ownerInfo!['photoUrl'] == '')
                                                ? const Icon(Icons.person, size: 40)
                                                : null,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _ownerInfo!['displayName'] ?? 'Без имени',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _ownerInfo!['email'] ?? 'Нет email',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          if (_ownerInfo!['phoneNumber'] != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              _ownerInfo!['phoneNumber'],
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ],
                                      ),
                                      actions: [
                                        if (!isOwner) ...[
                                          TextButton.icon(
                                            onPressed: () async {
                                              Navigator.pop(context); // Закрываем диалог с информацией
                                              final result = await showDialog<bool>(
                                                context: rootContext,
                                                builder: (context) => ReportDialog(
                                                  reporterId: user!.uid,
                                                  reportedUserId: widget.house.ownerId,
                                                  listingId: widget.house.id,
                                                  listingTitle: widget.house.title,
                                                ),
                                              );
                                              if (result == true) {
                                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Жалоба успешно отправлена'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.report_problem_outlined),
                                            label: const Text('Пожаловаться'),
                                          ),
                                        ],
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Закрыть'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!isOwner && widget.house.status == 'active') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => BookingDialog(
                                  house: widget.house,
                                  onSuccess: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Бронирование создано'),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_today, color: Colors.white),
                            label: Text(
                              'Забронировать',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: IconButton(
                            icon: _favoriteLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : colors.onSurface,
                                  size: 28,
                                ),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Только что';
        }
        return '${difference.inMinutes} ${_getMinutesText(difference.inMinutes)} назад';
      }
      return '${difference.inHours} ${_getHoursText(difference.inHours)} назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_getDaysText(difference.inDays)} назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  String _getMinutesText(int minutes) {
    if (minutes % 10 == 1 && minutes % 100 != 11) return 'минуту';
    if (minutes % 10 >= 2 && minutes % 10 <= 4 && (minutes % 100 < 12 || minutes % 100 > 14)) {
      return 'минуты';
    }
    return 'минут';
  }

  String _getHoursText(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) return 'час';
    if (hours % 10 >= 2 && hours % 10 <= 4 && (hours % 100 < 12 || hours % 100 > 14)) {
      return 'часа';
    }
    return 'часов';
  }

  String _getDaysText(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 12 || days % 100 > 14)) {
      return 'дня';
    }
    return 'дней';
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
        ],
      ),
    );
  }
}

class _OwnerInfo extends StatelessWidget {
  final String name;
  final String email;
  final String? photo;
  final VoidCallback onContact;

  const _OwnerInfo({
    required this.name,
    required this.email,
    required this.photo,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: photo != null ? NetworkImage(photo!) : null,
          child: photo == null ? const Icon(Icons.person, size: 30) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Владелец', style: theme.textTheme.labelSmall),
              Text(name, style: theme.textTheme.bodyLarge),
              Text(email, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              )),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.contact_page, color: theme.colorScheme.primary),
          onPressed: onContact,
        ),
      ],
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhoto;
  const ChatRoomPage({super.key, required this.userName, required this.userEmail, this.userPhoto});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: text, isMe: true));
        _controller.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userPhoto != null ? NetworkImage(widget.userPhoto!) : null,
              child: widget.userPhoto == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: theme.textTheme.bodyLarge),
                Text('Online', style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                )),
              ],
            ),
          ],
        ),
        elevation: 1,
        shadowColor: colors.outline.withOpacity(0.3),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? colors.primary.withOpacity(0.1)
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: message.isMe
                          ? Border.all(color: colors.primary.withOpacity(0.2))
                          : null,
                    ),
                    child: Text(message.text, style: theme.textTheme.bodyMedium),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.outline.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;

  ChatMessage({required this.text, required this.isMe});
}