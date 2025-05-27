import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/house_model.dart';
import '../services/booking_service.dart';

class BookingDialog extends StatefulWidget {
  final HouseModel house;
  final Function() onSuccess;

  const BookingDialog({
    super.key,
    required this.house,
    required this.onSuccess,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isLoading = false;
  String? _errorMessage;
  final _bookingService = BookingService();

  double get _totalPrice {
    if (_checkIn == null || _checkOut == null) return 0;
    final days = _checkOut!.difference(_checkIn!).inDays;
    return days * widget.house.price;
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
        _errorMessage = null;
      });
    }
  }

  Future<void> _createBooking() async {
    if (_checkIn == null || _checkOut == null) {
      setState(() => _errorMessage = 'Выберите даты заезда и выезда');
      return;
    }

    if (_checkOut!.difference(_checkIn!).inDays < 1) {
      setState(() => _errorMessage = 'Дата выезда должна быть позже даты заезда');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Проверяем доступность дат
      final isAvailable = await _bookingService.isDateRangeAvailable(
        widget.house.id,
        _checkIn!,
        _checkOut!,
      );

      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Выбранные даты недоступны';
          _isLoading = false;
        });
        return;
      }

      // Создаем бронирование
      await _bookingService.createBooking(
        houseId: widget.house.id,
        ownerId: widget.house.ownerId,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        totalPrice: _totalPrice,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Бронирование',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата заезда',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _checkIn == null
                                  ? 'Выберите дату'
                                  : '${_checkIn!.day}.${_checkIn!.month}.${_checkIn!.year}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: _checkIn == null
                                    ? colors.onSurface.withOpacity(0.6)
                                    : colors.onSurface,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: colors.primary),
                          ],
                        ),
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
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата выезда',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _checkOut == null
                                  ? 'Выберите дату'
                                  : '${_checkOut!.day}.${_checkOut!.month}.${_checkOut!.year}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: _checkOut == null
                                    ? colors.onSurface.withOpacity(0.6)
                                    : colors.onSurface,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_checkIn != null && _checkOut != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Итого',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_checkOut!.difference(_checkIn!).inDays} ночей',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${_totalPrice.toStringAsFixed(2)} ₽',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: colors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Забронировать',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 