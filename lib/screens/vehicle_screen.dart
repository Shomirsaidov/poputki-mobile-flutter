import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  int _totalSeats = 5;
  
  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicle();
  }

  Future<void> _fetchVehicle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await _apiClient.get('/users/${auth.user!.id}/vehicle');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _makeController.text = data['make'] ?? '';
          _modelController.text = data['model'] ?? '';
          _plateController.text = data['plate_number'] ?? '';
          _totalSeats = data['total_seats'] ?? 5;
        });
      }
    } catch (e) {
      print('Error fetching vehicle: $e');
    } finally {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final response = await _apiClient.post('/users/vehicle', data: {
        'user_id': auth.user!.id,
        'make': _makeController.text,
        'model': _modelController.text,
        'plate_number': _plateController.text,
        'total_seats': _totalSeats,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Транспорт успешно сохранен!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      print('Error saving vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Мой транспорт'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ДАННЫЕ АВТОМОБИЛЯ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Марка',
                      hint: 'Toyota',
                      controller: _makeController,
                      validator: (v) => v!.isEmpty ? 'Введите марку' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Модель',
                      hint: 'Camry',
                      controller: _modelController,
                      validator: (v) => v!.isEmpty ? 'Введите модель' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Гос. номер',
                      hint: '0000 AA 00',
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v!.isEmpty ? 'Введите номер' : null,
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 32),
                    const Text('КОЛИЧЕСТВО МЕСТ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          _buildCountButton(Icons.remove, () {
                            if (_totalSeats > 2) setState(() => _totalSeats--);
                          }),
                          Expanded(
                            child: Column(
                              children: [
                                Text('$_totalSeats', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const Text('мест', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          _buildCountButton(Icons.add, () {
                            if (_totalSeats < 10) setState(() => _totalSeats++);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: 'Сохранить автомобиль',
                      isLoading: _isLoading,
                      onPressed: _saveVehicle,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.textPrimary),
      ),
    );
  }
}
