import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../models/house_model.dart';
import '../widgets/property_card.dart';
import 'profile_page.dart';
import 'unauthenticated_profile_page.dart';
import 'house_details_page.dart';
import 'dart:io';
import 'favorites_page.dart';
import 'my_bookings_page.dart';

class HomePage extends StatefulWidget {
  final AuthService authService;
  final VoidCallback? onSignOut;
  const HomePage({super.key, required this.authService, this.onSignOut});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _sort = 'По умолчанию';
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Сначала новые', 'icon': Icons.access_time},
    {'value': 'price_asc', 'label': 'По возрастанию цены', 'icon': Icons.arrow_upward},
    {'value': 'price_desc', 'label': 'По убыванию цены', 'icon': Icons.arrow_downward},
  ];
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Список городов и выбранный город
  final List<String> _cities = [
    // Беларусь
    'Минск, Беларусь',
    'Брест, Беларусь',
    'Витебск, Беларусь',
    'Гомель, Беларусь',
    'Гродно, Беларусь',
    'Могилёв, Беларусь',
    // Россия
    'Москва, Россия',
    'Санкт-Петербург, Россия',
  ];
  String? _selectedCity;
  late AnimationController _cityAnimationController;
  static const String _selectedCityKey = 'selected_city';

  final _listingService = ListingService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  late AnimationController _cityController;
  
  String? _searchQuery;
  String _sortBy = 'newest';
  bool _isSearching = false;
  bool _isSorting = false;

  // Add a list to hold all listings
  List<HouseModel> _allListings = [];
  // Add a list to hold filtered listings
  List<HouseModel> _filteredListings = [];

  // Добавляем кэш для изображений
  final Map<String, ImageProvider> _imageCache = {};
  
  // Добавляем флаг для отложенной инициализации
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _cityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);
    _cityAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Добавляем слушатель на контроллер поиска
    _searchController.addListener(_onSearchChanged);
    
    // Отложенная инициализация
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
      _loadSortBy();
    });
  }

  @override
  void dispose() {
    _cityAnimationController.dispose();
    _scrollController.dispose();
    // Удаляем слушатель перед диспоузом контроллера
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;
    
    // Загружаем сохраненный город
    await _loadSavedCity();
    
    // Предварительно загружаем изображения для популярных объявлений
    _preloadPopularImages();
    
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _preloadPopularImages() async {
    try {
      final listings = await _listingService.getPopularListings(city: _selectedCity).first;
      for (final listing in listings) {
        if (listing.images.isNotEmpty) {
          final imageUrl = listing.images.first;
          if (imageUrl.startsWith('http')) {
            _precacheImage(imageUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка предзагрузки изображений: $e');
    }
  }

  Future<void> _precacheImage(String url) async {
    if (_imageCache.containsKey(url)) return;
    
    try {
      final imageProvider = NetworkImage(url);
      _imageCache[url] = imageProvider;
      
      // Предварительно загружаем изображение
      final image = Image(image: imageProvider);
      await precacheImage(imageProvider, context);
    } catch (e) {
      debugPrint('Ошибка кэширования изображения: $e');
    }
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_selectedCityKey);
    if (savedCity != null && _cities.contains(savedCity)) {
      setState(() => _selectedCity = savedCity);
    } else {
      setState(() => _selectedCity = _cities.first);
      await prefs.setString(_selectedCityKey, _cities.first);
    }
  }

  Future<void> _updateSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCityKey, city);
    _cityAnimationController.forward(from: 0.0);
    setState(() {
      _selectedCity = city;
      _currentPage = 0;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isLoadingMore) {
      _loadMoreListings();
    }
  }

  Future<void> _loadMoreListings() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(seconds: 1)); // Имитация загрузки
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 3) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(authService: widget.authService, onSignOut: widget.onSignOut),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnauthenticatedProfilePage(authService: widget.authService),
          ),
        );
      }
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavoritesPage(
            authService: widget.authService,
            onSignOut: widget.onSignOut,
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyBookingsPage(
            authService: widget.authService,
            onSignOut: widget.onSignOut,
          ),
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onSearchChanged() {
    // Вызываем setState, чтобы обновить UI при изменении текста поиска
    setState(() {
      _searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
      _applySearchFilter(); // Apply filter when search query changes
    });
  }

  // Add a method to apply the search filter to the list of all listings
  void _applySearchFilter() {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      _filteredListings = _allListings.where((listing) {
        final query = _searchQuery!.toLowerCase();
        return listing.title.toLowerCase().contains(query) ||
               listing.description.toLowerCase().contains(query);
      }).toList();
    } else {
      _filteredListings = List.from(_allListings); // If search is empty, show all listings
    }
  }

  void _showSortOptions() {
    setState(() => _isSorting = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
            child: Column(
          mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Сортировка',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _isSorting = false);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            _buildSortOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _sortOptions.length,
      itemBuilder: (context, index) {
        final option = _sortOptions[index];
        final isSelected = _sortBy == option['value'] as String;
        return ListTile(
          leading: Icon(
            option['icon'] as IconData,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
          title: Text(
            option['label'] as String,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
          onTap: () {
            setState(() {
              _sortBy = option['value'] as String;
              _isSorting = false;
            });
            _saveSortBy(_sortBy);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final isDefaultSort = _sortBy == 'newest';
    IconData sortIcon;
    Color sortColor;
    switch (_sortBy) {
      case 'price_asc':
        sortIcon = Icons.arrow_upward;
        sortColor = Colors.blueAccent;
        break;
      case 'price_desc':
        sortIcon = Icons.arrow_downward;
        sortColor = Colors.deepOrangeAccent;
        break;
      default:
        sortIcon = Icons.tune;
        sortColor = Colors.deepPurple;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3EFFF), Color(0xFFE8EAF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
        borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.montserrat(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Поиск объявлений...',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.deepPurple),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
                          ),
                        ),
                        Container(
            height: 40,
            width: 1,
            color: Colors.deepPurple.withOpacity(0.12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: sortColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showSortOptions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Icon(
                    sortIcon,
                    color: sortColor,
                    size: 24,
                  ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade600, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade200.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => _buildCitySelectionSheet(),
                        );
                      },
                        child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCity ?? 'Выберите город',
                              style: GoogleFonts.montserrat(
                            color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 22),
                          ],
                          ),
                        ),
                      ),
                    const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8F4FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: const Color(0xFF3B6B3B),
                      height: 100,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                              Text('ПОЛУЧИТЕ 10% КЭШБЭК', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                  SizedBox(height: 8),
                              Text('*Действует до 31 декабря 2025', 
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Image.asset(
                          'assets/house.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
              ],
            ),
          ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                'Популярные предложения',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
      height: 340,
            child: StreamBuilder<List<HouseModel>>(
                stream: _listingService.getPopularListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                    return const Center(child: Text('Нет популярных объявлений'));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () => _navigateToDetails(data[index]),
                        child: _buildPopularHouseCard(data[index]),
                    );
                  },
                );
              },
            ),
          ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Все объявления',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),

          StreamBuilder<List<HouseModel>>(
            stream: _listingService.getAllListings(
              city: _selectedCity,
              sortBy: _sortBy,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Ошибка: ${snapshot.error}'),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Update _allListings and apply filter when new data arrives
              _allListings = snapshot.data!;
              _applySearchFilter();

              if (_filteredListings.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 44,
                          color: Theme.of(context).disabledColor,
                        ),
                        Text(
                          _searchQuery != null && _searchQuery!.isNotEmpty
                              ? 'Ничего не найдено по запросу "${_searchQuery}"'
                              : 'Нет активных объявлений' + (_selectedCity != null && _selectedCity != _cities.first ? ' в ${_selectedCity}' : ''),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = _filteredListings[index]; // Use filtered list here
                      return Padding(
                         padding: const EdgeInsets.only(bottom: 16),
                         child: GestureDetector(
                            onTap: () => _navigateToDetails(listing),
                            child: _buildHouseCard(listing, width: double.infinity, height: 295, imageHeight: 180),
                         ),
                      );
                    },
                    childCount: _filteredListings.length,
                  ),
                ),
              );
            },
          ),

          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
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
            currentIndex: _currentIndex,
            onTap: _onNavItemTapped,
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
  }

  Widget _buildCategoryItem(IconData icon, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E88E5),
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
                          Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHouseCard(HouseModel house, {double? width, double? height, double? imageHeight}) {
    final img = house.images.isNotEmpty ? house.images.first : null;
    Widget imageWidget;
    final double? cardWidth = width;
    final double? cardHeight = height;
    final double? imgHeight = imageHeight;
    final double borderRadius = 18;
    final double priceFont = 15;
    final double titleFont = 16;
    final double locationFont = 14;
    final double iconSize = 18;
    final double statusFont = 13;
    final double pad = 16;
    final double chipPad = 4;
    final double chipFont = 13;

    if (img != null) {
      if (img.startsWith('http')) {
        imageWidget = Container(
          width: cardWidth,
          child: Image.network(
          img,
            height: imgHeight,
            width: cardWidth,
          fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _buildPlaceholder(width: cardWidth, height: imgHeight),
          ),
        );
      } else {
        imageWidget = Container(
          width: cardWidth,
          child: Image.file(
          File(img),
            height: imgHeight,
            width: cardWidth,
          fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _buildPlaceholder(width: cardWidth, height: imgHeight),
          ),
        );
      }
    } else {
      imageWidget = _buildPlaceholder(width: cardWidth, height: imgHeight);
    }

    Widget card = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                child: imageWidget,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: chipPad),
                  decoration: BoxDecoration(
                    color: house.status == 'pending' ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    house.status == 'pending' ? 'На проверке' : 'Активно',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: statusFont),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: chipPad),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${house.price} ₽',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: priceFont),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house.title,
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: titleFont),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.deepOrangeAccent, size: iconSize),
                    const SizedBox(width: 4),
                    Text(house.location, style: TextStyle(color: Colors.grey[600], fontSize: locationFont)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.king_bed_outlined, size: iconSize),
                    const SizedBox(width: 4),
                    Text('${house.bedrooms} спальни', style: TextStyle(fontSize: chipFont)),
                    const SizedBox(width: 16),
                    Icon(Icons.bathtub, size: iconSize),
                    const SizedBox(width: 4),
                    Text('${house.bathrooms} ванны', style: TextStyle(fontSize: chipFont)),
                    const SizedBox(width: 16),
                    Icon(Icons.square_foot, size: iconSize),
                    const SizedBox(width: 4),
                    Text('${house.area}м²', style: TextStyle(fontSize: chipFont)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (cardWidth != null && cardHeight != null) {
      return SizedBox(width: cardWidth, height: cardHeight, child: card);
    } else if (cardWidth != null) {
      return SizedBox(width: cardWidth, child: card);
    } else if (cardHeight != null) {
      return SizedBox(height: cardHeight, child: card);
    } else {
      return card;
    }
  }

  Widget _buildPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height ?? 170,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.home, size: 60, color: Colors.grey)),
    );
  }

  Widget _buildCitySelectionSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Выберите город',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = city == _selectedCity;
                return ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: isSelected ? Colors.deepPurple : Colors.grey,
                  ),
                  title: Text(
                    city,
                    style: GoogleFonts.montserrat(
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                      : null,
                  onTap: () {
                    _updateSelectedCity(city);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(HouseModel house) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HouseDetailsPage(house: house),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData outline, IconData filled, String label) {
    return BottomNavigationBarItem(
      icon: Icon(outline, size: 26),
      activeIcon: Icon(filled, size: 26),
      label: label,
    );
  }

  Widget _buildPopularHouseCard(HouseModel house) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 180,
              width: double.infinity,
              child: _buildHouseImage(house),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        house.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeatureItem('${house.bedrooms} спален', Icons.king_bed),
                    _buildFeatureItem('${house.bathrooms} ванн', Icons.bathtub),
                    _buildFeatureItem('${house.area}м²', Icons.square_foot),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${house.price} ₽',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Подробнее',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
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
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseImage(HouseModel house) {
    if (house.images.isEmpty) return _buildPlaceholder();
    return Image.network(
      house.images.first,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        return progress == null
            ? child
            : Container(
                height: 180,
                color: Colors.grey[100],
                child: Center(child: CircularProgressIndicator()),
              );
      },
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Future<void> _saveSortBy(String sortBy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortBy', sortBy);
  }

  Future<void> _loadSortBy() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getString('sortBy');
    if (savedSort != null && _sortOptions.any((o) => o['value'] == savedSort)) {
      setState(() {
        _sortBy = savedSort;
      });
    }
  }

  int get _sortIndex => _sortOptions.indexWhere((o) => o['value'] == _sortBy);
}

