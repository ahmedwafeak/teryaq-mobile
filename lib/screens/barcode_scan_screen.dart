import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  final String userId;

  const BarcodeScanScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _barcodeController = TextEditingController(text: '6281001234567');
  final TextEditingController _daysController = TextEditingController(text: '7');
  final TextEditingController _previousDosesController = TextEditingController(text: '10');

  bool _isLoading = false;
  bool _isCameraActive = true;
  Map<String, dynamic>? _scannedMedication;
  String? _statusMessage;

  // Extended Medication Form State
  bool _isChronic = true;
  bool _isFirstTimeUse = true;
  DateTime _previousStartDate = DateTime.now().subtract(const Duration(days: 14));

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    _daysController.dispose();
    _previousDosesController.dispose();
    super.dispose();
  }

  void _handleDetectBarcode(BarcodeCapture capture) {
    if (!_isCameraActive || _isLoading) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isCameraActive = false;
          _barcodeController.text = barcode.rawValue!;
        });
        _handleScanBarcode(barcode.rawValue!);
        break;
      }
    }
  }

  void _handleScanBarcode(String code) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _scannedMedication = null;
    });

    final res = await ApiService.lookupBarcode(code.trim());

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true && res['medication'] != null) {
      setState(() {
        _scannedMedication = res['medication'];
      });
    } else if (res['suggestedMedication'] != null) {
      setState(() {
        _scannedMedication = res['suggestedMedication'];
      });
    } else {
      setState(() {
        _statusMessage = res['message'] ?? 'تعذر العثور على دواء بالباركود.';
      });
    }
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _previousStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _previousStartDate = picked;
      });
    }
  }

  void _confirmAddMedication() async {
    if (_scannedMedication == null) return;

    setState(() {
      _isLoading = true;
    });

    final previousHistoryPayload = {
      'isFirstTime': _isFirstTimeUse,
      'startDate': _isFirstTimeUse ? DateTime.now().toString().split(' ')[0] : _previousStartDate.toString().split(' ')[0],
      'previousDosesCount': _isFirstTimeUse ? 0 : (int.tryParse(_previousDosesController.text) ?? 0),
    };

    final treatmentDurationPayload = {
      'isChronic': _isChronic,
      'totalDays': _isChronic ? null : (int.tryParse(_daysController.text) ?? 7),
    };

    final res = await ApiService.addMedication(
      userId: widget.userId,
      barcode: _scannedMedication!['barcode'] ?? 'N/A',
      name: _scannedMedication!['name'] ?? 'دواء جديد',
      dosage: _scannedMedication!['dosage'] ?? 'جرعة يومية واحدة',
      time: '08:00 AM',
      treatmentDuration: treatmentDurationPayload,
      dailySchedule: ['08:00 AM', '08:00 PM'],
      previousHistory: previousHistoryPayload,
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'تمت إضافة الدواء وتحديث السجل بنجاح!')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _statusMessage = res['message'] ?? 'فشل حفظ الدواء.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('مسح وإعداد الدواء 📷'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined, color: Colors.cyanAccent),
            onPressed: () {
              setState(() {
                _isCameraActive = !_isCameraActive;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isCameraActive
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: _handleDetectBarcode,
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 54, color: Color(0xFF38BDF8)),
                          SizedBox(height: 8),
                          Text(
                            '[ اضغط على أيقونة الكاميرا بالأعلى لتنشيط الفحص المباشر ]',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم الباركود',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : () => _handleScanBarcode(_barcodeController.text),
                  child: const Text('فحص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('كابوتين 6281001234567'),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  onPressed: () {
                    _barcodeController.text = '6281001234567';
                    _handleScanBarcode('6281001234567');
                  },
                ),
                ActionChip(
                  label: const Text('بندول 6281007654321'),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                  onPressed: () {
                    _barcodeController.text = '6281007654321';
                    _handleScanBarcode('6281007654321');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            else if (_scannedMedication != null) ...[
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'تم التعرف على الدواء!',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scannedMedication!['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الجرعة المعتادة: ${_scannedMedication!['dosage']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Section 1: Duration of Treatment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏱️ 1. مدة العلاج:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('دواء دائم / مزمن'),
                          selected: _isChronic,
                          selectedColor: const Color(0xFF0284C7),
                          onSelected: (selected) {
                            setState(() => _isChronic = true);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('دواء بأيام محددة'),
                          selected: !_isChronic,
                          selectedColor: const Color(0xFF0284C7),
                          onSelected: (selected) {
                            setState(() => _isChronic = false);
                          },
                        ),
                      ],
                    ),
                    if (!_isChronic) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'عدد الأيام الإجمالي للعلاج',
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Section 2: Previous Treatment History
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 2. سجل الاستخدام السلسلة:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      title: const Text('🟢 1- أول استخدام (بداية العلاج اليوم)', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: true,
                      groupValue: _isFirstTimeUse,
                      activeColor: Colors.green,
                      onChanged: (val) => setState(() => _isFirstTimeUse = val!),
                    ),
                    RadioListTile<bool>(
                      title: const Text('🔵 2- تم الاستخدام مسبقاً (مستمر عليه من قبل)', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: false,
                      groupValue: _isFirstTimeUse,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (val) => setState(() => _isFirstTimeUse = val!),
                    ),
                    if (!_isFirstTimeUse) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('تاريخ بداية أخذ الدواء سابقاً:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              subtitle: Text(
                                _previousStartDate.toString().split(' ')[0],
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              trailing: const Icon(Icons.calendar_today, color: Color(0xFF38BDF8)),
                              onTap: _selectStartDate,
                            ),
                            const Divider(color: Colors.grey),
                            TextField(
                              controller: _previousDosesController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'عدد المرات / الجرعات السابقة المتناولة',
                                labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text(
                  'تثبيت الدواء في جدول المريض 📌',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _confirmAddMedication,
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
