import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/seat_selector.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final ApiClient _apiClient = ApiClient();
  int _step = 1; // 1: Role, 2: Form, 3: Seats
  String _rideRole = 'driver'; // 'driver' or 'passenger'
  
  final TextEditingController _fromAddressController = TextEditingController();
  final TextEditingController _toAddressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String? _fromCity;
  String? _toCity;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  int _seats = 4;
  bool _allowsDelivery = false;
  
  List<String> _cities = [];
  bool _hasVehicle = false;
  int _vehicleTotalSeats = 5;
  bool _isLoading = false;
  List<int> _reservedSeats = [1];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (auth.user != null) {
        final response = await _apiClient.get('/users/${auth.user!.id}/vehicle');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _hasVehicle = true;
            _vehicleTotalSeats = response.data['total_seats'] ?? 5;
            _seats = _vehicleTotalSeats - 1;
          });
        }
      }
      
      final citiesRes = await _apiClient.get('/general/cities', queryParameters: {'type': 'ride'});
      if (citiesRes.statusCode == 200) {
        setState(() => _cities = List<String>.from(citiesRes.data));
      }
    } catch (e) {
      print('Error fetching initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectRole(String role) {
    if (role == 'driver' && !_hasVehicle) {
      _showNoVehicleDialog();
      return;
    }
    setState(() {
      _rideRole = role;
      _step = 2;
    });
  }

  void _showNoVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нужен автомобиль'),
        content: const Text('Для создания поездки в качестве водителя необходимо добавить данные автомобиля. Добавить сейчас?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('ОТМЕНА')),
          TextButton(
            onPressed: () {
              context.pop();
              context.push('/vehicle');
            },
            child: const Text('ДОБАВИТЬ'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRide() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final payload = {
        'driver_id': auth.user!.id,
        'from_city': _fromCity,
        'to_city': _toCity,
        'from_address': _rideRole == 'driver' ? _fromAddressController.text : null,
        'to_address': _rideRole == 'driver' ? _toAddressController.text : null,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
        'price': _rideRole == 'driver' ? int.tryParse(_priceController.text) ?? 0 : 0,
        'seats': _rideRole == 'driver' ? _seats : 1,
        'description': '',
        'is_passenger_entry': _rideRole == 'passenger',
        'reserved_seats': _rideRole == 'driver' ? _reservedSeats : [],
        'allows_delivery': _allowsDelivery,
        'total_seats': _rideRole == 'driver' ? _vehicleTotalSeats : 1,
      };

      final response = await _apiClient.post('/rides', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Успешно опубликовано!')),
          );
          context.go('/');
        }
      }
    } catch (e) {
      print('Error creating ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при создании поездки')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _step == 1 ? 'Создать поездку' : (_rideRole == 'driver' ? 'Я водитель' : 'Я пассажир'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _step > 1 ? IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => setState(() => _step--),
        ) : null,
      ),
      body: _isLoading && _step == 1
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(),
            ),
      bottomNavigationBar: _step > 1 ? _buildBottomBar() : null,
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildRoleCard(
          role: 'driver',
          title: 'Я Водитель',
          subtitle: 'У меня есть машина и я ищу попутчиков',
          icon: Icons.directions_car_rounded,
          color: Colors.amber,
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          role: 'passenger',
          title: 'Я Пассажир',
          subtitle: 'Ищу машину, чтобы доехать до места',
          icon: Icons.person_search_rounded,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _selectRole(role),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade100, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('МАРШРУТ'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              _buildCityDropdown(value: _fromCity, label: 'Откуда', onChanged: (v) => setState(() => _fromCity = v)),
              const Divider(height: 32),
              _buildCityDropdown(value: _toCity, label: 'Куда', onChanged: (v) => setState(() => _toCity = v)),
            ],
          ),
        ),
        if (_rideRole == 'driver') ...[
          const SizedBox(height: 24),
          CustomTextField(label: 'ТОЧНЫЙ АДРЕС ОТПРАВЛЕНИЯ', hint: 'Улица, дом', controller: _fromAddressController),
          const SizedBox(height: 16),
          CustomTextField(label: 'ТОЧНЫЙ АДРЕС ПРИБЫТИЯ', hint: 'Улица, дом', controller: _toAddressController),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildDatePicker()),
            const SizedBox(width: 16),
            Expanded(child: _buildTimePicker()),
          ],
        ),
        if (_rideRole == 'driver') ...[
          const SizedBox(height: 32),
          _buildSectionTitle('ЦЕНА И МЕСТА'),
          _buildPriceInput(),
          const SizedBox(height: 16),
          _buildSeatsCounter(),
          const SizedBox(height: 16),
          _buildDeliveryToggle(),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        SeatSelector(
          selectedSeats: const [],
          existingBookings: const [],
          reservedSeats: _reservedSeats,
          totalSeats: _vehicleTotalSeats,
          rowPrices: const {},
          isReservationMode: true,
          onSeatToggled: (id) {
            setState(() {
              if (_reservedSeats.contains(id)) {
                if (id != 1) _reservedSeats.remove(id);
              } else {
                _reservedSeats.add(id);
              }
            });
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Отметьте ${(_vehicleTotalSeats - 1) - _seats} занятых места на схеме',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
    );
  }

  Widget _buildCityDropdown({required String? value, required String label, required Function(String?) onChanged}) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(label),
        items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) setState(() => _date = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 12),
            Text(DateFormat('dd.MM').format(_date)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: _time);
        if (time != null) setState(() => _time = time);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 12),
            Text(_time.format(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Цена за место', style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 4),
              const Text('с.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Количество мест', style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _seats > 1 ? _seats-- : null), icon: const Icon(Icons.remove_circle_outline)),
              Text('$_seats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: () => setState(() => _seats < (_vehicleTotalSeats - 1) ? _seats++ : null), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Принимаю посылки', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Документы или пакеты', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Switch(value: _allowsDelivery, onChanged: (val) => setState(() => _allowsDelivery = val), activeColor: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: CustomButton(
        text: _step == 3 || (_step == 2 && _rideRole == 'passenger') ? 'ОПУБЛИКОВАТЬ' : 'ДАЛЕЕ',
        isLoading: _isLoading,
        onPressed: () {
          if (_step == 3 || (_step == 2 && _rideRole == 'passenger')) {
            _createRide();
          } else {
            if (_fromCity == null || _toCity == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите города')));
              return;
            }
            setState(() => _step++);
          }
        },
      ),
    );
  }
}
