import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';


class PassportOCRWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onDataExtracted;

  const PassportOCRWidget({super.key, required this.onDataExtracted});

  @override
  State<PassportOCRWidget> createState() => _PassportOCRWidgetState();
}

class _PassportOCRWidgetState extends State<PassportOCRWidget> {
  static const _ocrEndpoint =
      'https://xzvtjcqwmuezxyeerkki.supabase.co/functions/v1/ocr-passport';

  static const Map<String, String> _natMap = {
    'TJK': 'Таджикистан', 'TAJIKISTAN': 'Таджикистан',
    'RUS': 'Россия', 'RUSSIA': 'Россия',
    'UZB': 'Узбекистан', 'UZBEKISTAN': 'Узбекистан',
    'KAZ': 'Казахстан', 'KAZAKHSTAN': 'Казахстан',
    'KGZ': 'Кыргызстан', 'KYRGYZSTAN': 'Кыргызстан',
    'TKM': 'Туркменистан', 'TURKMENISTAN': 'Туркменистан',
    'BLR': 'Беларусь', 'BELARUS': 'Беларусь',
    'UKR': 'Украина', 'UKRAINE': 'Украина',
    'AZE': 'Азербайджан', 'AZERBAIJAN': 'Азербайджан',
    'ARM': 'Армения', 'ARMENIA': 'Армения',
    'GEO': 'Грузия', 'GEORGIA': 'Грузия',
  };

  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;

  /// Mirror the web's canvas compression: 1200×1200, quality ~0.6, target <200KB.
  /// Loops the quality down if the first pass is still too big.
  Future<Uint8List?> _compress(String path) async {
    for (final quality in [60, 45, 30, 20]) {
      final bytes = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 1200,
        minHeight: 1200,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (bytes == null) return null;
      if (bytes.lengthInBytes <= 200 * 1024) return bytes;
    }
    // Fall back to the last (smallest) attempt even if still over 200KB.
    return await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1000,
      minHeight: 1000,
      quality: 15,
      format: CompressFormat.jpeg,
    );
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      Uint8List? bytes = await _compress(image.path);
      bytes ??= await File(image.path).readAsBytes();

      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final dio = Dio(BaseOptions(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ));

      final response = await dio.post(
        _ocrEndpoint,
        data: {'img': base64Image},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if (data['status'] != 'OK') {
        throw Exception(data['message']?.toString() ?? 'Ошибка распознавания');
      }

      final msg = (data['message'] as Map).cast<String, dynamic>();

      // ---- Name parsing (matches web BusBookingView.vue) ----
      String lastName =
          (msg['surname'] ?? msg['lastName'] ?? msg['last_name'] ?? '').toString();
      String firstName = (msg['givenName'] ??
              msg['given_name'] ??
              msg['firstName'] ??
              msg['first_name'] ??
              '')
          .toString();

      if (lastName.isEmpty && firstName.isEmpty && msg['name'] != null) {
        final cleanName = msg['name']
            .toString()
            .replaceAll(RegExp(r'<+'), ' ')
            .replaceAll(',', '')
            .trim();
        final parts = cleanName.split(RegExp(r'\s+'));
        lastName = parts.isNotEmpty ? parts[0] : '';
        firstName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      // ---- Birth date: YYYYMMDD or YYYY-MM-DD → YYYY-MM-DD ----
      final rawBirth = (msg['birthDay'] ??
              msg['birth_day'] ??
              msg['dateOfBirth'] ??
              msg['date_of_birth'] ??
              '')
          .toString();
      String birthDate = '';
      if (rawBirth.contains('-')) {
        birthDate = rawBirth;
      } else if (rawBirth.length == 8) {
        birthDate =
            '${rawBirth.substring(0, 4)}-${rawBirth.substring(4, 6)}-${rawBirth.substring(6, 8)}';
      }

      // ---- Nationality ----
      final rawNat =
          ((msg['nationality'] ?? msg['country'] ?? '').toString()).toUpperCase();
      final citizenship =
          _natMap[rawNat] ?? (msg['nationality'] ?? msg['country'] ?? 'Таджикистан').toString();

      // ---- Doc number ----
      final docNum = (msg['passportNumber'] ??
              msg['passport_number'] ??
              msg['doc_number'] ??
              '')
          .toString();

      // ---- Gender ----
      final rawGender = (msg['gender'] ?? msg['sex'] ?? '').toString().toUpperCase();
      final gender = (rawGender == 'M' || rawGender == 'MALE')
          ? 'male'
          : (rawGender == 'F' || rawGender == 'FEMALE')
              ? 'female'
              : '';

      widget.onDataExtracted({
        'lastName': lastName,
        'firstName': firstName,
        'middleName': (msg['middleName'] ?? msg['middle_name'] ?? '').toString(),
        'birthDate': birthDate,
        'gender': gender,
        'docNumber': docNum,
        'citizenship': citizenship,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно извлечены')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сканирования: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickAndScan(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickAndScan(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF9333EA)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: _isScanning ? null : _showSourcePicker,
          child: Column(
            children: [
              if (_isScanning) ...[
                const SizedBox(height: 10),
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 16),
                const Text('Распознаем паспорт...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ] else ...[
                const Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB), size: 32),
                const SizedBox(height: 12),
                const Text('СКАНИРОВАТЬ ПАСПОРТ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2563EB))),
                const Text('Автоматическое заполнение данных', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
