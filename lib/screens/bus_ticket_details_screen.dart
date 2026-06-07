import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bus_ticket.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'package:intl/intl.dart';

class BusTicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  const BusTicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<BusTicketDetailsScreen> createState() => _BusTicketDetailsScreenState();
}

class _BusTicketDetailsScreenState extends State<BusTicketDetailsScreen> {
  final ApiClient _apiClient = ApiClient();
  BusTicket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/bus-tickets/${widget.ticketId}');
      if (response.statusCode == 200) {
        setState(() {
          _ticket = BusTicket.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching ticket: $e');
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ticket == null) {
      return const Scaffold(body: Center(child: Text('Билет не найден')));
    }

    final availableSeats = _ticket!.totalSeats - (_ticket!.bookedSeats?.length ?? 0).toInt();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainCard(availableSeats),
                  const SizedBox(height: 24),
                  if (_ticket!.photos != null && _ticket!.photos!.isNotEmpty) ...[
                    _buildPhotoGallery(),
                    const SizedBox(height: 24),
                  ],
                  _buildRouteSection(),
                  const SizedBox(height: 24),
                  if (_ticket!.passengerComments != null) ...[
                    _buildCommentSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildCompanyInfo(),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: availableSeats > 0 ? 'Купить билет' : 'Мест нет',
                    onPressed: availableSeats > 0 
                      ? () => context.push('/bus-booking/${_ticket!.id}')
                      : null,
                    color: const Color(0xFF2563EB),
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  if (_ticket!.operatorPhone != null)
                    _buildOperatorButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF2563EB),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '${_ticket!.fromCity} → ${_ticket!.toCity}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildMainCard(int availableSeats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDatePlace(_ticket!.departureDate, _ticket!.departureTime, _ticket!.fromCity, true),
              _buildDurationInfo(),
              _buildDatePlace(_ticket!.arrivalDate, _ticket!.arrivalTime, _ticket!.toCity, false),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Цена билета', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${_ticket!.price.toInt()} с.',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Свободно', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '$availableSeats',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: availableSeats > 5 ? Colors.green : (availableSeats > 0 ? Colors.orange : Colors.red)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePlace(String dateStr, String time, String city, bool isStart) {
    final date = DateTime.parse(dateStr);
    return Expanded(
      child: Column(
        crossAxisAlignment: isStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(
            DateFormat('d MMMM', 'ru').format(date),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            city,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textSecondary),
            textAlign: isStart ? TextAlign.left : TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            '${_ticket!.durationMinutes ~/ 60} ч ${_ticket!.durationMinutes % 60} м',
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              Container(width: 40, height: 2, color: Colors.blue.withOpacity(0.2)),
              const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ФОТОГРАФИИ АВТОБУСА',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ticket!.photos!.length,
            itemBuilder: (context, index) {
              final photo = _ticket!.photos![index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(photo['url']),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ДЕТАЛИ МАРШРУТА',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(
            time: _ticket!.departureTime,
            label: 'ОТПРАВЛЕНИЕ',
            city: _ticket!.fromCity,
            address: _ticket!.fromAddress,
            isFirst: true,
          ),
          if (_ticket!.intermediateStops != null)
            ..._ticket!.intermediateStops!.map((stop) => _buildTimelineItem(
              time: stop['time'] ?? '',
              label: 'ОСТАНОВКА',
              city: stop['city'],
              address: stop['address'],
            )).toList(),
          _buildTimelineItem(
            time: _ticket!.arrivalTime,
            label: 'ПРИБЫТИЕ',
            city: _ticket!.toCity,
            address: _ticket!.toAddress,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String label,
    required String city,
    String? address,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isFirst || isLast ? const Color(0xFF2563EB) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2563EB), width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.2), blurRadius: 4)],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withOpacity(0.1)],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
              if (address != null)
                Text(address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('КОММЕНТАРИЙ К РЕЙСУ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${_ticket!.passengerComments}"',
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E40AF), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.directions_bus_outlined, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ПЕРЕВОЗЧИК', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                Text(_ticket!.transportCompany ?? 'Транспортная компания', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorButton() {
    return CustomButton(
      text: 'Позвонить оператору',
      onPressed: () => launchUrl(Uri.parse('tel:${_ticket!.operatorPhone}')),
      color: Colors.grey.shade100,
      textColor: AppTheme.textPrimary,
    );
  }
}
