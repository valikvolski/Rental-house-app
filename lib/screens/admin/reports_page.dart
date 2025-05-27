import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/report_model.dart';
import '../../models/house_model.dart';
import '../../services/report_service.dart';
import '../../services/user_service.dart';
import '../../services/listing_service.dart';
import '../house_details_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  final _reportService = ReportService();
  final _userService = UserService();
  final _listingService = ListingService();
  late TabController _tabController;
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = 'active';
            break;
          case 1:
            _selectedStatus = 'resolved';
            break;
          case 2:
            _selectedStatus = 'rejected';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showResolutionDialog(ReportModel report) async {
    final resolutionController = TextEditingController();
    String selectedAction = 'resolved';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Решение жалобы',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Причина: ${report.reason}'),
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Детали: ${report.details}'),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAction,
              decoration: InputDecoration(
                labelText: 'Действие',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text('Решено'),
                ),
                DropdownMenuItem(
                  value: 'rejected',
                  child: Text('Отклонено'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedAction = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              decoration: InputDecoration(
                labelText: 'Комментарий к решению',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _reportService.updateReportStatus(
          reportId: report.id,
          status: selectedAction,
          adminId: FirebaseFirestore.instance.collection('users').doc().id, // TODO: Get actual admin ID
          resolutionNote: resolutionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Статус жалобы обновлен')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Жалобы',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrangeAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrangeAccent,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Решенные'),
            Tab(text: 'Отклоненные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList('active'),
          _buildReportsList('resolved'),
          _buildReportsList('rejected'),
        ],
      ),
    );
  }

  Widget _buildReportsList(String status) {
    return StreamBuilder<List<ReportModel>>(
      stream: status == 'active'
          ? _reportService.getActiveReports()
          : _reportService.getAllReports().map(
              (reports) => reports.where((r) => r.status == status).toList(),
            ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return Center(
            child: Text(
              'Нет жалоб',
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(report.status),
                    style: TextStyle(
                      color: _getStatusColor(report.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('listings').doc(report.listingId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final listing = snapshot.data!.data() as Map<String, dynamic>?;
                if (listing == null) return const SizedBox.shrink();

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HouseDetailsPage(
                          house: HouseModel.fromMap(listing),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing['title'] ?? 'Объявление',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepPurple,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 18, color: Colors.deepPurple),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Причина: ${report.reason}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Детали: ${report.details}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(report.reportedUserId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Ошибка загрузки данных пользователя',
                        style: TextStyle(color: Colors.red[600]),
                      );
                    }
                    
                    if (!snapshot.hasData) {
                      return const Text('Загрузка...');
                    }
                    
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final email = userData?['email'] ?? 'Неизвестно';
                    
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'На пользователя:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            email,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                if (report.status == 'active')
                  ElevatedButton(
                    onPressed: () => _showResolutionDialog(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Решить'),
                  ),
              ],
            ),
            if (report.status != 'active') ...[
              const SizedBox(height: 12),
              Text(
                'Решено: ${_formatDate(report.resolvedAt!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (report.resolutionNote != null && report.resolutionNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Комментарий: ${report.resolutionNote}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'resolved':
        return 'Решено';
      case 'rejected':
        return 'Отклонено';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 