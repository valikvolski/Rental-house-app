import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../../services/booking_service.dart'; // Import BookingService
import '../../models/booking_model.dart'; // Import BookingModel
import '../../services/listing_service.dart'; // Import ListingService to get house details
import '../../models/house_model.dart'; // Import HouseModel
import 'package:firebase_auth/firebase_auth.dart';

class RentalAnalyticsPage extends StatefulWidget {
  const RentalAnalyticsPage({super.key});

  @override
  State<RentalAnalyticsPage> createState() => _RentalAnalyticsPageState();
}

class _RentalAnalyticsPageState extends State<RentalAnalyticsPage> {
  final BookingService _bookingService = BookingService();
  final ListingService _listingService = ListingService(); // To fetch house details
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // You might add date range selection variables and logic here later

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser; // Get current user

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Аналитика аренды')),
        body: Center(child: Text('Необходима авторизация')),
      );
    }

    // Use StreamBuilder to get user data and role
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
             appBar: AppBar(title: Text('Аналитика аренды')),
             body: Center(child: CircularProgressIndicator()),
          );
        }
        if (userSnapshot.hasError) {
          return Scaffold(
             appBar: AppBar(title: Text('Аналитика аренды')),
             body: Center(child: Text('Ошибка загрузки данных пользователя: ${userSnapshot.error}')),
          );
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
           return Scaffold(
             appBar: AppBar(title: Text('Аналитика аренды')),
             body: Center(child: Text('Данные пользователя не найдены')),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final userRole = userData?['role'] ?? 'user'; // Get user role


        // Determine the correct stream based on user role
        Stream<List<BookingModel>> bookingsStream;
         if (userRole == 'admin') { // Check if user is admin
           bookingsStream = _bookingService.getAllBookingsStream();
         } else { // Assume landlord or other role who sees their own listings bookings
           // For landlords, use their UID to get bookings for their properties
           bookingsStream = _bookingService.getBookingsByOwnerIdStream(currentUser.uid);
         }


        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Аналитика аренды',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
          body: StreamBuilder<List<BookingModel>>(
            stream: bookingsStream, // Use the determined stream
            builder: (context, bookingSnapshot) { // Use bookingSnapshot for clarity
              if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (bookingSnapshot.hasError) {
                return Center(child: Text('Ошибка загрузки аналитики: ${bookingSnapshot.error}'));
              }
              if (!bookingSnapshot.hasData || bookingSnapshot.data!.isEmpty) {
                return const Center(child: Text('Нет данных для аналитики'));
              }

              final bookings = bookingSnapshot.data!;

              // --- Analytical Calculations --- This part remains similar

              // 1. Общее количество аренд за период (сейчас за все время)
              final totalBookings = bookings.length;

              // 2. Количество сданных домов по периодам (пока общее количество уникальных домов)
              final uniqueHouseIds = bookings.map((b) => b.houseId).toSet();
              final totalUniqueHouses = uniqueHouseIds.length;

              // 3. Популярные дома (Топ-5 по количеству бронирований)
              final Map<String, int> bookingCounts = {};
              for (final booking in bookings) {
                bookingCounts.update(booking.houseId, (value) => value + 1, ifAbsent: () => 1);
              }

              final sortedHouseIds = bookingCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              // Get house IDs that actually exist in bookingCounts after sorting
              final topPopularHouseIds = sortedHouseIds
                  .take(5)
                  .where((entry) => bookingCounts.containsKey(entry.key))
                  .map((entry) => entry.key)
                  .toList();


              // --- UI Layout --- This part remains similar
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Обзор аналитики',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total Bookings Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blueAccent, size: 36),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Общее количество бронирований',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalBookings.toString(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Unique Houses Card
                     Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.home_work_outlined, color: Colors.green, size: 36),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Уникальные сданные объекты',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalUniqueHouses.toString(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Популярные объекты',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Popular Listings List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(), // To disable scrolling within the list
                      itemCount: topPopularHouseIds.length,
                      itemBuilder: (context, index) {
                        final houseId = topPopularHouseIds[index];
                        final bookingCount = bookingCounts[houseId] ?? 0;
                        
                        // Fetch house details for popular listings
                        return FutureBuilder<HouseModel?>(
                          future: _listingService.getListing(houseId), // Use ListingService to get house details
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const ListTile(
                                title: Text('Загрузка...'),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                               return ListTile(
                                title: Text('Ошибка загрузки объекта $houseId'),
                              );
                            }
                            final house = snapshot.data!;
                            return Card(
                               margin: const EdgeInsets.only(bottom: 8),
                               elevation: 2,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               child: ListTile(
                                 leading: house.images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          house.images.first,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                           errorBuilder: (c, e, s) => Icon(Icons.broken_image),
                                        ),
                                      )
                                    : const Icon(Icons.home_outlined, size: 40),
                                  title: Text(house.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${house.location}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                       Text('$bookingCount', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                       Text('бронирований', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                  onTap: () {
                                    // Navigate to house details if needed
                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => HouseDetailsPage(house: house)));
                                  },
                               ),
                            );
                          },
                        );
                      },
                    ),
                    
                    // You might add more sections here for time-based analysis later
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
