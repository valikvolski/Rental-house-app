import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/house_model.dart';
import '../../services/admin/admin_service.dart';
import 'dart:io';

import '../edit_listing_page.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  final AdminService _adminService = AdminService();
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Модерация объявлений',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: StreamBuilder<List<HouseModel>>(
              stream: _filter == 'pending'
                  ? _adminService.getPendingHouses()
                  : _adminService.getAllHouses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка: ${snapshot.error}',
                      style: GoogleFonts.montserrat(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final houses = snapshot.data!;
                if (houses.isEmpty) {
                  return Center(
                    child: Text(
                      _filter == 'pending'
                          ? 'Нет объявлений на модерацию'
                          : 'Нет объявлений',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: houses.length,
                  itemBuilder: (context, index) {
                    final house = houses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (house.images.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: PageView.builder(
                                itemCount: house.images.length,
                                itemBuilder: (context, index) {
                                  final img = house.images[index];
                                  if (img.startsWith('http')) {
                                    return Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.error_outline,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    return Image.file(
                                      File(img),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.error_outline,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  house.location,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildFeatureChip(
                                      Icons.bed,
                                      '${house.bedrooms} спален',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFeatureChip(
                                      Icons.bathtub_outlined,
                                      '${house.bathrooms} ванных',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFeatureChip(
                                      Icons.square_foot,
                                      '${house.area} м²',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  house.description,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${house.price} ₽',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        _getStatusText(house.status),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(house.status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _editHouse(house),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Редактировать'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _deleteHouse(house),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Удалить'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    if (house.status == 'pending') ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _approveHouse(house),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Одобрить'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _rejectHouse(house),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Отклонить'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('На модерации'),
              selected: _filter == 'pending',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filter = 'pending');
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: const Text('Все объявления'),
              selected: _filter == 'all',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filter = 'all');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'На модерации';
      case 'active':
        return 'Активно';
      case 'rejected':
        return 'Отклонено';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editHouse(HouseModel house) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingPage(house: house),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление обновлено')),
      );
    }
  }

  Future<void> _approveHouse(HouseModel house) async {
    try {
      await _adminService.approveHouse(house.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление одобрено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _rejectHouse(HouseModel house) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина отклонения'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Введите причину отклонения',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text);
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _adminService.rejectHouse(house.id!, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объявление отклонено')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteHouse(HouseModel house) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина удаления'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Введите причину удаления',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _adminService.updateHouse(house.copyWith(status: 'deleted', rejectionReason: reason));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объявление удалено')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
} 