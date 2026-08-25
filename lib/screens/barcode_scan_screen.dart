import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  final String userId;

  const BarcodeScanScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final TextEditingController _barcodeController = TextEditingController(text: '6281001234567');
  bool _isLoading = false;
  Map<String, dynamic>? _scannedMedication;
  String? _statusMessage;

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

  void _confirmAddMedication() async {
    if (_scannedMedication == null) return;

    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.addMedication(
      userId: widget.userId,
      barcode: _scannedMedication!['barcode'] ?? 'N/A',
      name: _scannedMedication!['name'] ?? 'دواء جديد',
      dosage: _scannedMedication!['dosage'] ?? 'جرعة يومية واحدة',
      time: '08:00 AM',
    );

    setState(() {
      _isLoading = false;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'تمت إضافة الدواء بنجاح!')),
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
        title: const Text('مسح باركود الدواء 📷'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 10),
                  const Text(
                    '[ الكاميرا نشطة - يتم فحص الباركود ]',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'أدخل أو اختر رقم باركود علبة الدواء للاختبار:',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
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
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'تم التعرف على الدواء بنجاح!',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اسم الدواء: ${_scannedMedication!['name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الجرعة المعتادة: ${_scannedMedication!['dosage']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      if (_scannedMedication!['category'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'التصنيف: ${_scannedMedication!['category']}',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.playlist_add, color: Colors.white),
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
