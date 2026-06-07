import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/ride.dart';
import '../widgets/custom_button.dart';
import '../widgets/seat_selector.dart';

class RideSeatSelectionScreen extends StatefulWidget {
  final String rideId;
  const RideSeatSelectionScreen({super.key, required this.rideId});

  @override
  State<RideSeatSelectionScreen> createState() => _RideSeatSelectionScreenState();
}

class _RideSeatSelectionScreenState extends State<RideSeatSelectionScreen> {
  final ApiClient _apiClient = ApiClient();
  Ride? _ride;
  bool _isLoading = true;
  bool _isBooking = false;
  List<int> _selectedSeats = [];
  Map<int, String> _seatGenders = {};

  @override
  void initState() {
    super.initState();
    _fetchRide();
  }

  Future<void> _fetchRide() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/rides/${widget.rideId}');
      if (response.statusCode == 200) {
        setState(() {
          _ride = Ride.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching ride: $e');
      if (mounted) context.pop();
    }
  }

  Future<void> _bookSeats() async {
    if (_selectedSeats.isEmpty) return;

    // Check if genders are selected
    for (var seatId in _selectedSeats) {
      if (!_seatGenders.containsKey(seatId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, выберите пол для места №$seatId')),
        );
        return;
      }
    }

    setState(() => _isBooking = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bookings = _selectedSeats.map((id) => {
        'seat_number': id,
        'passenger_gender': _seatGenders[id],
      }).toList();

      final response = await _apiClient.post('/bookings', data: {
        'ride_id': _ride!.id,
        'passenger_id': auth.user!.id,
        'seats': bookings,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Успешно забронировано!')),
          );
          context.pop(); // Back to details
        }
      }
    } catch (e) {
      print('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при бронировании')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ride == null) {
      return const Scaffold(body: Center(child: Text('Поездка не найдена')));
    }

    double totalPrice = 0;
    for (var id in _selectedSeats) {
      String row = 'row2';
      if (id <= 2) row = 'front';
      else if (id > 5) row = 'row3';
      totalPrice += _ride!.rowPrices?[row] ?? _ride!.price;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Выбор места'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SeatSelector(
              selectedSeats: _selectedSeats,
              existingBookings: _ride!.bookings ?? [],
              reservedSeats: _ride!.reservedSeats ?? [],
              totalSeats: _ride!.totalSeats,
              rowPrices: _ride!.rowPrices ?? {},
              onSeatToggled: (id) {
                setState(() {
                  if (_selectedSeats.contains(id)) {
                    _selectedSeats.remove(id);
                    _seatGenders.remove(id);
                  } else {
                    _selectedSeats.add(id);
                  }
                });
              },
            ),
            const SizedBox(height: 32),
            if (_selectedSeats.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ИНФОРМАЦИЯ О ПАССАЖИРАХ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              ..._selectedSeats.map((id) => _buildGenderSelector(id)).toList(),
            ],
            const SizedBox(height: 32),
            _buildBottomBar(totalPrice),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector(int seatId) {
    final selectedGender = _seatGenders[seatId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Место №$seatId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGenderButton(seatId, 'male', 'Мужчина', Icons.male, selectedGender == 'male'),
                const SizedBox(width: 12),
                _buildGenderButton(seatId, 'female', 'Женщина', Icons.female, selectedGender == 'female'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(int seatId, String gender, String label, IconData icon, bool isActive) {
    final color = gender == 'male' ? Colors.blue : Colors.pink;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _seatGenders[seatId] = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? color : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? color : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(double totalPrice) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ИТОГО', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text('${totalPrice.toInt()} с.', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: _isBooking ? 'Бронируем...' : (_selectedSeats.isEmpty ? 'Выберите место' : 'Забронировать'),
            onPressed: _selectedSeats.isEmpty || _isBooking ? null : () => _bookSeats(),
            isLoading: _isBooking,
          ),
        ),
      ],
    );
  }
}
