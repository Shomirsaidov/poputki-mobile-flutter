import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/bus_ticket.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/bus_seat_selector.dart';
import '../widgets/passenger_form.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'payment_webview_screen.dart';

class BusBookingScreen extends StatefulWidget {
  final String ticketId;
  final int initialStep;
  const BusBookingScreen({super.key, required this.ticketId, this.initialStep = 1});

  @override
  State<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  final ApiClient _apiClient = ApiClient();
  BusTicket? _ticket;
  bool _isLoading = true;
  bool _isBooking = false;

  late int _currentStep;
  int _passengerCount = 1;
  List<int> _selectedSeats = [];
  List<Map<String, dynamic>> _passengersData = [];
  String _phone = '';
  String? _pickupCity;
  String? _dropOffCity;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
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
          _pickupCity = _ticket!.fromCity;
          _dropOffCity = _ticket!.toCity;
          _buildInitialPassengers(1);
        });
      }
    } catch (e) {
      print('Error fetching ticket: $e');
      if (mounted) context.pop();
    }
  }

  void _buildInitialPassengers(int count) {
    _passengersData = List.generate(count, (index) => {
      'index': index + 1,
      'gender': '',
      'lastName': '',
      'firstName': '',
      'middleName': '',
      'birthDate': '',
      'citizenship': 'Таджикистан',
      'docType': 'Внутренний паспорт',
      'docNumber': '',
      'isExpanded': true,
    });
  }

  void _onPassengerCountChange(int newCount) {
    setState(() {
      _passengerCount = newCount;
      _selectedSeats = [];
      _buildInitialPassengers(newCount);
    });
  }

  bool _canProceedStep1() => _selectedSeats.length == _passengerCount;

  bool _canProceedStep2() {
    for (var p in _passengersData) {
      if (p['gender'].isEmpty || p['lastName'].isEmpty || p['firstName'].isEmpty || 
          p['birthDate'].isEmpty || p['docNumber'].isEmpty) {
        return false;
      }
    }
    return _phone.isNotEmpty && _pickupCity != null && _dropOffCity != null;
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final payload = {
        'bus_ticket_id': int.parse(widget.ticketId),
        'passenger_id': auth.user!.id,
        'seat_numbers': _selectedSeats,
        'passengers_data': _passengersData,
        'phone': _phone,
        'pickup_city': _pickupCity,
        'drop_off_city': _dropOffCity,
      };

      final response = await _apiClient.post('/payments/create-invoice', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final paymentLink = response.data['payment_link'] as String?;
        if (paymentLink != null && paymentLink.isNotEmpty) {
          final uri = Uri.parse(paymentLink.trim());
          bool launched = false;
          try {
            launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            launched = false;
          }
          if (launched) {
            if (mounted) context.go('/');
          } else {
            if (mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentWebviewScreen(paymentUrl: paymentLink.trim()),
                  fullscreenDialog: true,
                ),
              );
            }
          }
        } else {
          _showError('Ссылка на оплату не получена');
        }
      }
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? (e.response!.data['error'] ?? e.response!.data.toString())
          : e.response?.data?.toString() ?? e.message ?? 'Ошибка сети';
      _showError('Ошибка: $serverMsg');
    } catch (e) {
      _showError('Неизвестная ошибка: $e');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_currentStep > 1) {
                    setState(() => _currentStep--);
                  } else {
                    context.pop();
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_ticket!.fromCity} → ${_ticket!.toCity}',
                      style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12),
                    ),
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
                child: Text('$_currentStep / 3', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(3, (index) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentStep > index ? Colors.white : Colors.white.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Выбор мест';
      case 2: return 'Данные пассажиров';
      case 3: return 'Подтверждение';
      default: return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 20),
        _buildPassengerCountSelector(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('СХЕМА САЛОНА', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 20),
              BusSeatSelector(
                selectedSeats: _selectedSeats,
                bookedSeats: _ticket!.bookedSeats ?? [],
                premiumSeats: _ticket!.premiumSeats ?? [],
                totalSeats: _ticket!.totalSeats,
                floor1Seats: _ticket!.floor1Seats ?? 20,
                floor2Seats: _ticket!.floor2Seats ?? 56,
                maxSelectable: _passengerCount,
                busType: _ticket!.busType,
                onSeatToggled: (id) {
                  setState(() {
                    if (_selectedSeats.contains(id)) {
                      _selectedSeats.remove(id);
                    } else if (_selectedSeats.length < _passengerCount) {
                      _selectedSeats.add(id);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ОТПРАВЛЕНИЕ', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('${_ticket!.departureTime} · ${DateFormat('d MMM', 'ru').format(DateTime.parse(_ticket!.departureDate))}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('ИТОГО', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('${(_ticket!.price * _passengerCount).toInt()} с.', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF2563EB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCountSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Количество пассажиров', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              _buildCounterButton(Icons.remove, () {
                if (_passengerCount > 1) _onPassengerCountChange(_passengerCount - 1);
              }),
              SizedBox(width: 40, child: Text('$_passengerCount', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              _buildCounterButton(Icons.add, () {
                if (_passengerCount < 6) _onPassengerCountChange(_passengerCount + 1);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildRoutePicker(),
        const SizedBox(height: 20),
        ...List.generate(_passengerCount, (index) => PassengerForm(
          index: index,
          data: _passengersData[index],
          seatNumber: _selectedSeats.length > index ? _selectedSeats[index] : null,
          onChanged: (newData) {
            setState(() {
              _passengersData[index] = newData;
            });
          },
        )),
        const SizedBox(height: 20),
        _buildPhoneInput(),
      ],
    );
  }

  Widget _buildRoutePicker() {
    final cities = [_ticket!.fromCity, ...(_ticket!.intermediateStops?.map((s) => s['city'] as String).toList() ?? []), _ticket!.toCity];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('МАРШРУТ ПОЕЗДКИ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _pickupCity,
            decoration: const InputDecoration(labelText: 'Город посадки'),
            items: cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _pickupCity = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _dropOffCity,
            decoration: const InputDecoration(labelText: 'Город высадки'),
            items: cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _dropOffCity = val),
          ),
        ],
      ),
    );
  }


  Widget _buildPhoneInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: TextField(
        keyboardType: TextInputType.phone,
        onChanged: (val) => setState(() => _phone = val),
        decoration: const InputDecoration(
          labelText: 'Контактный телефон',
          prefixIcon: Icon(Icons.phone_outlined),
          hintText: '+992 ...',
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildFinalTicketPreview(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ДЕТАЛИ БРОНИРОВАНИЯ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 16),
              _buildSummaryRow('Пассажиров', '$_passengerCount чел.'),
              _buildSummaryRow('Места', _selectedSeats.join(', ')),
              _buildSummaryRow('Сумма', '${(_ticket!.price * _passengerCount).toInt()} с.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinalTicketPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 40)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTicketHalf(_ticket!.fromCity, DateFormat('d MMMM', 'ru').format(DateTime.parse(_ticket!.departureDate))),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
              ),
              Expanded(
                child: _buildTicketHalf(_ticket!.toCity, DateFormat('d MMMM', 'ru').format(DateTime.parse(_ticket!.arrivalDate)), isRight: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHalf(String city, String date, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          city, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          date, 
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: CustomButton(
        text: _getButtonText(),
        isLoading: _isBooking,
        onPressed: _canProceed() ? () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _confirmBooking();
          }
        } : null,
      ),
    );
  }

  String _getButtonText() {
    if (_isBooking) return 'Бронируем...';
    if (_currentStep == 3) return 'Оплатить ${(_ticket!.price * _passengerCount).toInt()} с.';
    return 'Далее';
  }

  bool _canProceed() {
    if (_currentStep == 1) return _canProceedStep1();
    if (_currentStep == 2) return _canProceedStep2();
    return true;
  }
}
