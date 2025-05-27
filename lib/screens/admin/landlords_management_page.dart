import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:course1/screens/admin/landlord_listings_page.dart';

class LandlordsManagementPage extends StatelessWidget {
  const LandlordsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Арендодатели', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['landlord', 'admin'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return Center(child: Text('Нет арендодателей', style: GoogleFonts.montserrat(fontSize: 16)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              user['documentId'] = users[index].id;
              return _buildLandlordCard(context, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildLandlordCard(BuildContext context, Map<String, dynamic> user) {
    // Safely extract user data with null checks and default values
    final String photoUrl = user['photoUrl']?.toString() ?? '';
    final String name = user['displayName']?.toString() ?? 'Без имени';
    final String email = user['email']?.toString() ?? 'Нет email';
    final String phone = user['phoneNumber']?.toString() ?? 'Нет телефона';
    final String age = user['age']?.toString() ?? 'Не указан';
    final String uid = user['uid']?.toString() ?? user['documentId']?.toString() ?? '';
    final bool isBlocked = user['isBlocked'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeature(Icons.email, email, 'Email'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFeature(Icons.phone, phone, 'Телефон'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildFeature(Icons.cake, age, 'Возраст'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final userId = user['uid'] ?? user['documentId'];
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LandlordListingsPage(
                            userId: userId.toString(),
                            userName: name,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Объявления'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(isBlocked ? Icons.lock_open : Icons.lock),
                  label: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBlocked ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Show confirmation dialog before blocking
                    if (!isBlocked) { // Only show dialog when blocking
                      final bool confirmBlock = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Подтверждение блокировки'),
                          content: const Text('Вы уверены, что хотите заблокировать этого пользователя? Заблокированный пользователь не сможет создавать новые объявления.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false), // User cancelled
                              child: const Text('Отмена'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true), // User confirmed
                              child: const Text('Заблокировать'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ) ?? false; // Default to false if dialog is dismissed

                      if (!confirmBlock) {
                        return; // Do not proceed if user cancelled
                      }
                    }

                    // Proceed with blocking/unblocking
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user['uid'] ?? user['documentId'])
                        .update({'isBlocked': !isBlocked});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBlocked ? 'Пользователь разблокирован' : 'Пользователь заблокирован'),
                      ),
                    );
                  },
                ),
              ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
} 