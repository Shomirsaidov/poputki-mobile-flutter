import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BusSeatSelector extends StatefulWidget {
  final List<int> selectedSeats;
  final List<int> bookedSeats;
  final List<int> premiumSeats;
  final int totalSeats;
  final int floor1Seats;
  final int floor2Seats;
  final int maxSelectable;
  final String? busType;
  final Function(int) onSeatToggled;

  const BusSeatSelector({
    super.key,
    required this.selectedSeats,
    required this.bookedSeats,
    required this.premiumSeats,
    required this.totalSeats,
    required this.floor1Seats,
    required this.floor2Seats,
    required this.maxSelectable,
    this.busType,
    required this.onSeatToggled,
  });

  @override
  State<BusSeatSelector> createState() => _BusSeatSelectorState();
}

class _BusSeatSelectorState extends State<BusSeatSelector> {
  int _currentFloor = 2; // Default to upper floor for double decker

  @override
  void initState() {
    super.initState();
    if (widget.busType != 'double') {
      _currentFloor = 1;
    }
  }

  List<int> get _doubleDeckPremiumSeats {
    final floor2Front = [1, 2, 3, 4];
    final f2 = widget.floor2Seats;
    final floor1VIP = <int>[];
    for (int i = 1; i <= 10; i++) {
      final seatNum = f2 + i;
      if (seatNum <= f2 + widget.floor1Seats) {
        floor1VIP.add(seatNum);
      }
    }
    
    final otherPremium = (widget.premiumSeats).where((s) {
      if (s > f2 && s <= f2 + widget.floor1Seats) return floor1VIP.contains(s);
      return true;
    }).toList();
    
    return {...floor2Front, ...floor1VIP, ...otherPremium}.toList();
  }

  bool _isSeatPremium(int seatNum) {
    if (widget.busType != 'double') return false;
    return _doubleDeckPremiumSeats.contains(seatNum);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Схема может отличаться от реальности',
          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (widget.busType == 'double') _buildFloorSwitcher(),
        const SizedBox(height: 20),
        _buildLayout(),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildFloorSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildFloorButton(1, '1 Этаж'),
          _buildFloorButton(2, '2 Этаж'),
        ],
      ),
    );
  }

  Widget _buildFloorButton(int floor, String label) {
    final isActive = _currentFloor == floor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFloor = floor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF2563EB) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout() {
    if (widget.busType == 'single') {
      return _buildSingleFloorLayout();
    }
    return _currentFloor == 1 ? _buildDoubleFloor1Layout() : _buildDoubleFloor2Layout();
  }

  Widget _buildSingleFloorLayout() {
    final List<Widget> rows = [];
    final max = widget.totalSeats;

    // Header labels
    rows.add(_buildGridRow([
      _buildLabelTile('TV', span: 2),
      const SizedBox.shrink(),
      _buildLabelTile('EXIT', variant: 'exit', span: 2),
    ]));

    // Driver row
    rows.add(_buildGridRow([
      _buildDriverCell(),
      _buildGuideCell('1 в'),
      const SizedBox.shrink(),
      _buildGuideCell('2 в'),
      const SizedBox.shrink(),
    ]));

    // Initial rows 1-20
    for (int i = 0; i < 5; i++) {
      final start = i * 4 + 1;
      rows.add(_buildSeatRow([start, start + 1], [start + 2, start + 3], max));
    }

    // WC and Middle Exit
    if (max > 20) {
      rows.add(_buildGridRow([
        ...[21, 22].map((s) => s <= max ? _buildSeat(s) : const SizedBox.shrink()),
        const SizedBox.shrink(),
        _buildLabelTile('TV', variant: 'tv', isSmall: true),
        _buildLabelTile('WC', variant: 'wc', isSmall: true),
      ]));
    }

    if (max > 22) {
      rows.add(_buildGridRow([
        ...[23, 24].map((s) => s <= max ? _buildSeat(s) : const SizedBox.shrink()),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        _buildLabelTile('EXIT', variant: 'exit', isSmall: true),
      ]));
    }

    // Dynamic rows
    int current = 25;
    while (current <= max) {
      final remaining = max - current + 1;
      if (remaining <= 5) {
        final lastSeats = List.generate(remaining, (i) => current + i);
        rows.add(_buildLastRow(lastSeats));
        break;
      } else {
        rows.add(_buildSeatRow([current, current + 1], [current + 2, current + 3], max));
        current += 4;
      }
    }

    return Column(children: rows);
  }

  Widget _buildDoubleFloor2Layout() {
    final List<Widget> rows = [];
    final max = widget.floor2Seats;

    rows.add(_buildGridRow([
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      _buildLabelTile('ЛЕСТНИЦА', variant: 'stairs'),
      const SizedBox.shrink(),
    ]));

    int seat = 1;
    while (seat <= max) {
      rows.add(_buildSeatRow([seat, seat + 1], [seat + 3, seat + 2], max));
      seat += 4;
    }

    rows.add(_buildGridRow([
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      _buildLabelTile('ЛЕСТНИЦА', variant: 'stairs', span: 2),
    ]));

    return Column(children: rows);
  }

  Widget _buildDoubleFloor1Layout() {
    final List<Widget> rows = [];
    final f2 = widget.floor2Seats;
    final max = f2 + widget.floor1Seats;

    rows.add(_buildGridRow([
      _buildLabelTile('ЛЕСТНИЦА', variant: 'stairs'),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      _buildLabelTile('ВХОД', variant: 'exit'),
    ]));

    // First row
    rows.add(_buildGridRow([
      _buildLabelTile('ЛЕСТНИЦА', variant: 'stairs', span: 2),
      const SizedBox.shrink(),
      ...[f2 + 2, f2 + 1].map((s) => s <= max ? _buildSeat(s) : const SizedBox.shrink()),
    ]));

    // Second row
    rows.add(_buildSeatRow([f2 + 3, f2 + 4], [f2 + 6, f2 + 5], max));

    // Table
    if (widget.floor1Seats >= 10) {
      rows.add(_buildGridRow([
        _buildTableCell('СТОЛ', span: 2),
        const SizedBox.shrink(),
        _buildTableCell('СТОЛ', span: 2),
      ]));
    }

    int seat = f2 + 7;
    while (seat <= max) {
      rows.add(_buildSeatRow([seat, seat + 1], [seat + 3, seat + 2], max));
      seat += 4;
    }

    rows.add(_buildGridRow([
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      _buildLabelTile('ВЫХОД', variant: 'exit', span: 2),
    ]));

    return Column(children: rows);
  }

  Widget _buildGridRow(List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((w) {
          if (w is SizedBox) return const SizedBox(width: 50, height: 50);
          return SizedBox(width: 50, height: 50, child: w);
        }).toList(),
      ),
    );
  }

  Widget _buildSeatRow(List<int> left, List<int> right, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...left.map((s) => s <= max ? _buildSeat(s) : const SizedBox(width: 50, height: 50)),
          const SizedBox(width: 30), // Aisle
          ...right.map((s) => s <= max ? _buildSeat(s) : const SizedBox(width: 50, height: 50)),
        ],
      ),
    );
  }

  Widget _buildLastRow(List<int> seats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: seats.map((s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildSeat(s),
        )).toList(),
      ),
    );
  }

  Widget _buildSeat(int id) {
    final isBooked = widget.bookedSeats.contains(id);
    final isSelected = widget.selectedSeats.contains(id);
    final isPremium = _isSeatPremium(id);

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Color textColor = AppTheme.textPrimary;

    if (isBooked) {
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
    } else if (isSelected) {
      bgColor = const Color(0xFF2563EB);
      borderColor = const Color(0xFF1E40AF);
      textColor = Colors.white;
    } else if (isPremium) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFBBF24);
      textColor = const Color(0xFF92400E);
    }

    return GestureDetector(
      onTap: isBooked ? null : () => widget.onSeatToggled(id),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$id',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor),
              ),
              if (isPremium && !isSelected && !isBooked)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(Icons.star, size: 10, color: Colors.orange),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelTile(String text, {String variant = 'default', int span = 1, bool isSmall = false}) {
    Color bg = const Color(0xFFF8FAFC);
    Color color = const Color(0xFF64748B);
    Color border = const Color(0xFFCBD5E1);

    if (variant == 'exit') {
      bg = const Color(0xFFFFFBEB);
      color = const Color(0xFF92400E);
      border = const Color(0xFFFBBF24);
    } else if (variant == 'stairs') {
      bg = const Color(0xFFF1F5F9);
      color = const Color(0xFF94A3B8);
    } else if (variant == 'tv') {
      bg = const Color(0xFFEFF6FF);
      color = const Color(0xFF1E40AF);
      border = const Color(0xFFBFDBFE);
    } else if (variant == 'wc') {
      bg = const Color(0xFFF5F3FF);
      color = const Color(0xFF5B21B6);
      border = const Color(0xFFDDD6FE);
    }

    return Container(
      width: span * 50.0,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: isSmall ? 9 : 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _buildTableCell(String text, {int span = 2}) {
    return Container(
      width: span * 50.0,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey),
      ),
    );
  }

  Widget _buildDriverCell() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildGuideCell(String text) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Выбрано', const Color(0xFF2563EB)),
        _buildLegendItem('Свободно', Colors.white, border: Colors.grey.shade300),
        _buildLegendItem('Занято', Colors.grey.shade100, border: Colors.grey.shade200),
        if (widget.busType == 'double') _buildLegendItem('Премиум', const Color(0xFFFFFBEB), border: const Color(0xFFFBBF24)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      ],
    );
  }
}
