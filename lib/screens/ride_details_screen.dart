import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/ride.dart';
import '../widgets/custom_button.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  const RideDetailsScreen({super.key, required this.rideId});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final ApiClient _apiClient = ApiClient();
  Ride? _ride;
  bool _isLoading = true;
  bool _isPhoneExpanded = false;

  String _formatRideDate(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      String dayPart;
      if (dateStr == now.toIso8601String().split('T')[0]) {
        dayPart = 'Сегодня';
      } else if (dateStr == tomorrow.toIso8601String().split('T')[0]) {
        dayPart = 'Завтра';
      } else {
        dayPart = DateFormat('d MMMM', 'ru').format(date);
      }
      
      return '$dayPart в $timeStr';
    } catch (e) {
      return '$dateStr в $timeStr';
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось совершить звонок на $phone')),
        );
      }
    }
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке поездки')),
        );
        context.pop();
      }
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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = auth.user?.id == _ride!.driverId;
    final hasBooked = _ride!.bookings?.any((b) => b['passenger_id'] == auth.user?.id) ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_ride!.isPassengerEntry) _buildPriceCard(),
                  if (_ride!.isPassengerEntry) _buildPassengerEntryAlert(),
                  const SizedBox(height: 32),
                  _buildDriverInfo(hasBooked),
                  if (_isPhoneExpanded && hasBooked) _buildPhonePanel(),
                  const SizedBox(height: 32),
                  if (!_ride!.isPassengerEntry) ...[
                    _buildVehicleInfo(),
                    const SizedBox(height: 32),
                    _buildPreferences(),
                    const SizedBox(height: 32),
                    _buildPassengersList(),
                  ],
                  const SizedBox(height: 40),
                  _buildActionButtons(isDriver, hasBooked),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(color: Colors.grey.shade100), // Map placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.05), Colors.white],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          _formatRideDate(_ride!.date, _ride!.time),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRouteDisplay(),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            top: 24,
            bottom: 24,
            child: Container(width: 2, color: Colors.grey.shade200),
          ),
          Column(
            children: [
              _buildRoutePoint(_ride!.fromCity, _ride!.fromAddress, Colors.blue),
              const SizedBox(height: 24),
              _buildRoutePoint(_ride!.toCity, _ride!.toAddress, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint(String city, String? address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              if (address != null)
                Text(address, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    final minPrice = _ride!.price; // Simplified
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ЦЕНА ЗА МЕСТО', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '${minPrice.toInt()} с.',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.payments_outlined, color: Colors.green, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerEntryAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, const Color(0xFFEEF2FF)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ИЩУ МАШИНУ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
                SizedBox(height: 4),
                Text(
                  'Это предложение от пассажира. Водителю необходимо создать аналогичную поездку.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(bool hasBooked) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              if (_ride!.driverId != null) {
                context.push('/user-profile/${_ride!.driverId}');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(_ride!.driverName?[0] ?? 'D', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ride!.driverName ?? 'Водитель', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(_ride!.driverRating?.toString() ?? '5.0', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasBooked && _ride!.driverPhone != null)
          IconButton.filled(
            onPressed: () => setState(() => _isPhoneExpanded = !_isPhoneExpanded),
            icon: const Icon(Icons.phone),
            style: IconButton.styleFrom(backgroundColor: Colors.green),
          ),
      ],
    );
  }

  Widget _buildPhonePanel() {
    return GestureDetector(
      onTap: () => _makeCall(_ride!.driverPhone),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.textPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.textPrimary.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, color: Colors.white),
            const SizedBox(width: 16),
            Text(_ride!.driverPhone!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.copy, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    if (_ride!.vehicle == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('АВТОМОБИЛЬ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_car, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_ride!.vehicle!['make']} ${_ride!.vehicle!['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text(_ride!.vehicle!['plate_number'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences() {
    if (_ride!.driverPreferences == null || _ride!.driverPreferences!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ПРЕДПОЧТЕНИЯ ВОДИТЕЛЯ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ride!.driverPreferences!.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(p.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPassengersList() {
    final bookings = _ride!.bookings ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ПАССАЖИРЫ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
            Text('${(bookings.length + (_ride!.reservedSeats?.where((id) => id != 1).length ?? 0))} / ${(_ride!.totalSeats - 1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ride!.totalSeats - 1, // Number of passenger seats
          itemBuilder: (context, index) {
            final seatId = index + 2; // Passenger seats start from 2
            final booking = _ride!.bookings?.firstWhere((b) => b['seat_number'] == seatId, orElse: () => null);
            final isReserved = _ride!.reservedSeats?.contains(seatId) ?? false;

            if (booking != null) {
              final isFemale = booking['passenger_gender'] == 'female' || booking['sex'] == 'female';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFDBEAFE),
                        child: Text(isFemale ? '👩' : '👨', style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Text(booking['passenger_name'] ?? 'Попутчик', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Место №$seatId', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              );
            } else if (isReserved) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Text('Место забронировано', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('Место №$seatId', style: TextStyle(fontSize: 10, color: Colors.grey.shade300)),
                    ],
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade50, child: const Icon(Icons.person, size: 14, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Text('Свободное место', style: TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text('Место №$seatId', style: TextStyle(fontSize: 10, color: Colors.grey.shade200)),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDriver, bool hasBooked) {
    if (isDriver) {
      return CustomButton(text: 'Управление поездкой', onPressed: () {});
    }

    if (hasBooked) {
      return CustomButton(
        text: 'Позвонить водителю',
        onPressed: () => _makeCall(_ride!.driverPhone),
        color: Colors.green,
      );
    }

    return Column(
      children: [
        CustomButton(
          text: 'Выбрать место',
          onPressed: () async {
            await context.push('/ride/${_ride!.id}/select-seat');
            _fetchRide(); // Auto refresh
          },
        ),
        if (_ride!.allowsDelivery) ...[
          const SizedBox(height: 12),
          CustomButton(
            text: 'Отдать посылку',
            onPressed: () {},
            color: Colors.amber.shade100,
            textColor: Colors.amber.shade900,
          ),
        ],
      ],
    );
  }
}
