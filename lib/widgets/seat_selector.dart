import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeatSelector extends StatelessWidget {
  final List<int> selectedSeats;
  final List<dynamic> existingBookings;
  final List<int> reservedSeats;
  final int totalSeats;
  final Map<String, dynamic> rowPrices;
  final Function(int) onSeatToggled;
  final bool isReservationMode; // New parameter

  const SeatSelector({
    super.key,
    required this.selectedSeats,
    required this.existingBookings,
    required this.reservedSeats,
    required this.totalSeats,
    required this.rowPrices,
    required this.onSeatToggled,
    this.isReservationMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isReservationMode ? 'Забронируйте места' : 'Схема салона',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          isReservationMode 
            ? 'ОТМЕТЬТЕ МЕСТА, КОТОРЫЕ УЖЕ ЗАНЯТЫ' 
            : 'НАЖМИТЕ НА СВОБОДНОЕ МЕСТО ДЛЯ ВЫБОРА',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFFEEF2FF), width: 2),
          ),
          child: Column(
            children: [
              _buildRow('front'),
              const SizedBox(height: 16),
              _buildRow('row2'),
              const SizedBox(height: 16),
              _buildRow('row3'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String rowName) {
    final rowSeats = _getSeatsForRow(rowName);
    if (rowSeats.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowSeats.map((seat) {
        final isDriver = seat['id'] == 1;
        final isSelected = selectedSeats.contains(seat['id']);
        final booking = _getBookingForSeat(seat['id']);
        final isReserved = reservedSeats.contains(seat['id']);
        final isBooked = booking != null;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildSeatButton(
              id: seat['id'],
              isDriver: isDriver,
              isSelected: isSelected,
              isBooked: isBooked,
              isReserved: isReserved,
              gender: booking?['passenger_gender'] ?? booking?['sex'],
              price: rowPrices[rowName]?.toDouble(),
              onTap: () => onSeatToggled(seat['id']),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatButton({
    required int id,
    required bool isDriver,
    required bool isSelected,
    required bool isBooked,
    required bool isReserved,
    String? gender,
    double? price,
    required VoidCallback onTap,
  }) {
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Widget? icon;

    if (isDriver) {
      bgColor = Colors.grey.shade100;
      icon = const Icon(Icons.circle_outlined, color: Colors.grey, size: 24);
    } else if (isBooked) {
      if (gender == 'male') {
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF60A5FA);
        icon = const Icon(Icons.person, color: Color(0xFF3B82F6), size: 24);
      } else if (gender == 'female') {
        bgColor = const Color(0xFFFDF2F8);
        borderColor = const Color(0xFFF472B6);
        icon = const Icon(Icons.person, color: Color(0xFFEC4899), size: 24);
      } else {
        bgColor = Colors.grey.shade100;
        icon = const Icon(Icons.person, color: Colors.grey, size: 24);
      }
    } else if (isReserved) {
      if (isReservationMode) {
        bgColor = AppTheme.textPrimary;
        borderColor = AppTheme.textPrimary;
        icon = const Icon(Icons.lock_outline, color: Colors.white, size: 24);
      } else {
        bgColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        icon = const Icon(Icons.lock_outline, color: Colors.grey, size: 20);
      }
    } else if (isSelected) {
      bgColor = AppTheme.textPrimary;
      borderColor = AppTheme.textPrimary;
      icon = const Icon(Icons.check, color: Colors.white, size: 24);
    } else {
      icon = Icon(Icons.airline_seat_recline_normal, color: Colors.grey.shade300, size: 24);
    }

    return GestureDetector(
      onTap: (isDriver || (!isReservationMode && (isBooked || isReserved))) ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: (isSelected || (isReservationMode && isReserved))
                  ? [BoxShadow(color: AppTheme.textPrimary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) icon,
                  Text(
                    isDriver ? 'ВОДИТЕЛЬ' : '№$id',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: (isSelected || (isReservationMode && isReserved)) ? Colors.white70 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (price != null && !isDriver && !isBooked && !isReserved && !isSelected && !isReservationMode)
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                ),
                child: Text(
                  '${price.toInt()}с.',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSeatsForRow(String rowName) {
    final List<Map<String, dynamic>> allSeats = [];
    
    // Front Row
    allSeats.add({'id': 1, 'row': 'front'});
    if (totalSeats >= 2) {
      allSeats.add({'id': 2, 'row': 'front'});
    }

    // Row 2
    int remaining = totalSeats - 2;
    int currentId = 3;
    int row2Count = remaining > 3 ? 3 : remaining;
    for (int i = 0; i < row2Count; i++) {
      allSeats.add({'id': currentId++, 'row': 'row2'});
    }
    remaining -= row2Count;

    // Row 3
    int row3Count = remaining > 3 ? 3 : remaining;
    for (int i = 0; i < row3Count; i++) {
      allSeats.add({'id': currentId++, 'row': 'row3'});
    }

    return allSeats.where((s) => s['row'] == rowName).toList();
  }

  Map<String, dynamic>? _getBookingForSeat(int seatId) {
    for (var booking in existingBookings) {
      if (booking['seat_number'] == seatId) return booking;
    }
    return null;
  }
}
