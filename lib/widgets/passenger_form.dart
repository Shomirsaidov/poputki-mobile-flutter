import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'passport_ocr_widget.dart';

class PassengerForm extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final int? seatNumber;
  final Function(Map<String, dynamic>) onChanged;

  const PassengerForm({
    super.key,
    required this.index,
    required this.data,
    this.seatNumber,
    required this.onChanged,
  });

  @override
  State<PassengerForm> createState() => _PassengerFormState();
}

class _PassengerFormState extends State<PassengerForm> {
  static const _textKeys = ['lastName', 'firstName', 'middleName', 'docNumber'];

  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final k in _textKeys) k: TextEditingController(text: widget.data[k]?.toString() ?? ''),
    };
  }

  @override
  void didUpdateWidget(PassengerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when parent data changes from outside (e.g. OCR fill).
    // Skip if text already matches to avoid clobbering cursor while typing.
    for (final k in _textKeys) {
      final next = widget.data[k]?.toString() ?? '';
      if (_controllers[k]!.text != next) {
        _controllers[k]!.text = next;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(widget.data);
    newData[key] = value;
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.data['isExpanded'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildHeader(isExpanded),
          if (isExpanded) _buildForm(context),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isExpanded) {
    return GestureDetector(
      onTap: () => _update('isExpanded', !isExpanded),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(24),
            bottom: Radius.circular(isExpanded ? 0 : 24),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Пассажир ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (widget.seatNumber != null)
                    Text('Место №${widget.seatNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PassportOCRWidget(
            onDataExtracted: (ocrData) {
              final newData = Map<String, dynamic>.from(widget.data);
              // Only overwrite when OCR actually returned a value — keeps prior
              // user input intact if a field is blank in the scan.
              ocrData.forEach((key, value) {
                if (value != null && value.toString().isNotEmpty) {
                  newData[key] = value;
                }
              });
              widget.onChanged(newData);
            },
          ),
          const SizedBox(height: 24),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          _buildTextField('Фамилия *', 'lastName', 'Иванов'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Имя *', 'firstName', 'Иван')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Отчество', 'middleName', 'Иванович')),
            ],
          ),
          const SizedBox(height: 16),
          _buildDatePicker(context, 'Дата рождения *', 'birthDate'),
          const SizedBox(height: 16),
          _buildCitizenshipSelector(),
          const SizedBox(height: 16),
          _buildDocTypeSelector(),
          const SizedBox(height: 16),
          _buildTextField('Серия / Номер документа *', 'docNumber', 'AA 1234567'),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(child: _buildGenderButton('male', 'Мужчина', Icons.male)),
        const SizedBox(width: 12),
        Expanded(child: _buildGenderButton('female', 'Женщина', Icons.female)),
      ],
    );
  }

  Widget _buildGenderButton(String gender, String label, IconData icon) {
    final isActive = widget.data['gender'] == gender;
    final color = gender == 'male' ? Colors.blue : Colors.pink;
    return GestureDetector(
      onTap: () => _update('gender', gender),
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
    );
  }

  Widget _buildTextField(String label, String key, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[key],
          onChanged: (val) => _update(key, val),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, String key) {
    final value = (widget.data[key] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _update(key, DateFormat('yyyy-MM-dd').format(date));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.isEmpty ? 'Выберите дату' : value, style: TextStyle(color: value.isEmpty ? Colors.grey : AppTheme.textPrimary)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCitizenshipSelector() {
    final countries = ["Таджикистан", "Россия", "Узбекистан", "Казахстан", "Кыргызстан", "Другое"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ГРАЖДАНСТВО *', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: countries.contains(widget.data['citizenship']) ? widget.data['citizenship'] : 'Другое',
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => _update('citizenship', val),
        ),
      ],
    );
  }

  Widget _buildDocTypeSelector() {
    final docs = ["Внутренний паспорт", "Загран паспорт", "Свидетельство о рождении"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ТИП ДОКУМЕНТА *', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: docs.contains(widget.data['docType']) ? widget.data['docType'] : docs[0],
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          items: docs.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (val) => _update('docType', val),
        ),
      ],
    );
  }
}
