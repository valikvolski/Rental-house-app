import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/house_model.dart';
import '../house_details_page.dart';

class LandlordListingsPage extends StatelessWidget {
  final String userId;
  final String userName;
  const LandlordListingsPage({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Объявления $userName', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: \\${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('Нет объявлений', style: GoogleFonts.montserrat(fontSize: 16)));
          }
          final houses = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return HouseModel.fromMap(data);
          }).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return _buildHouseCard(context, house);
            },
          );
        },
      ),
    );
  }

  Widget _buildHouseCard(BuildContext context, HouseModel house) {
    final img = house.images.isNotEmpty ? house.images.first : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Переход на подробную страницу объявления
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: house.status == 'pending' ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      house.status == 'pending' ? 'На проверке' : 'Активно',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          house.location,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFeature(Icons.king_bed_outlined, '${house.bedrooms}', 'спален'),
                      const SizedBox(width: 16),
                      _buildFeature(Icons.bathtub, '${house.bathrooms}', 'ванных'),
                      const SizedBox(width: 16),
                      _buildFeature(Icons.square_foot, '${house.area}', 'м²'),
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
        Icon(icon, size: 16, color: Colors.grey.shade600),
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