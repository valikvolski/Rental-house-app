import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String reporterId;
  final String reportedUserId;
  final String listingId;
  final String listingTitle;

  const ReportDialog({
    super.key,
    required this.reporterId,
    required this.reportedUserId,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reportService = ReportService();
  String _selectedReason = '';
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _reasons = [
    'Некорректная информация',
    'Мошенничество',
    'Спам',
    'Оскорбления',
    'Неприемлемый контент',
    'Другое',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason.isEmpty) {
      setState(() => _errorMessage = 'Пожалуйста, выберите причину жалобы');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Проверяем, нет ли уже активной жалобы
      final hasActive = await _reportService.hasActiveReport(
        reporterId: widget.reporterId,
        listingId: widget.listingId,
      );

      if (hasActive) {
        setState(() {
          _errorMessage = 'У вас уже есть активная жалоба на это объявление';
          _isSubmitting = false;
        });
        return;
      }

      // Создаем новую жалобу
      final report = ReportModel(
        id: '', // ID будет установлен в сервисе
        reporterId: widget.reporterId,
        reportedUserId: widget.reportedUserId,
        listingId: widget.listingId,
        reason: _selectedReason,
        details: _detailsController.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
      );

      await _reportService.createReport(report);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true при успешной отправке
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при отправке жалобы: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Отправить жалобу',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Объявление: ${widget.listingTitle}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Причина жалобы:',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedReason = selected ? reason : '';
                        _errorMessage = null;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.deepOrangeAccent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.deepOrangeAccent : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Дополнительные детали (необязательно)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Максимальная длина - 500 символов';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Отправить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 