import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'alarm_ring_screen.dart';
import 'barcode_scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _userId;
  List<dynamic> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = widget.userData['patientId'] ?? 'user-default';
    _fetchUserMedications();
  }

  void _fetchUserMedications() async {
    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.getUserMedications(_userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true && res['medications'] != null) {
          _medications = res['medications'];
        } else {
          _medications = [
            {
              'id': 'med-1',
              'name': widget.userData['medication'] ?? 'كابوتين 25mg',
              'dosage': 'جرعة واحدة 08:00 صباحاً',
              'treatmentDuration': {'isChronic': true, 'totalDays': null},
              'previousHistory': {'isFirstTime': true, 'startDate': '2026-08-01', 'previousDosesCount': 0},
              'time': '08:00 AM'
            }
          ];
        }
      });
    }
  }

  void _openBarcodeScanner() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanScreen(userId: _userId),
      ),
    );

    if (added == true) {
      _fetchUserMedications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.userData['patientName'] ?? 'المريض';
    final caregiverPhone = widget.userData['caregiverPhone'] ?? '+966500000000';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('أهلاً بك، $patientName'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUserMedications,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نسبة الالتزام بالجرعات',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Icon(Icons.stars, color: Colors.amber, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '100% - ممتاز! 🌟',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'مُشرف الرعاية المرتبط: $caregiverPhone',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'جدول أدوية الحساب المسجلة:',
                  style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                  label: const Text('إضافة بالباركود 📷', style: TextStyle(color: Colors.white, fontSize: 12)),
                  onPressed: _openBarcodeScanner,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : ListView.builder(
                      itemCount: _medications.length,
                      itemBuilder: (context, index) {
                        final med = _medications[index];
                        final medName = med['name'] ?? 'دواء عام';
                        final dosage = med['dosage'] ?? 'جرعة يومية واحدة';
                        final duration = med['treatmentDuration'];
                        final isChronic = duration != null ? (duration['isChronic'] ?? true) : true;
                        final totalDays = duration != null ? duration['totalDays'] : null;

                        final prevHistory = med['previousHistory'];
                        final isFirstTime = prevHistory != null ? (prevHistory['isFirstTime'] ?? true) : true;
                        final startDate = prevHistory != null ? prevHistory['startDate'] : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFF0284C7),
                                      child: Icon(Icons.medication, color: Colors.white),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medName,
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dosage,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber[700],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AlarmRingScreen(
                                              patientName: patientName,
                                              medicationName: medName,
                                              caregiverPhone: caregiverPhone,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('محاكاة المنبه ⏰', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(color: Colors.grey),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Chip(
                                      backgroundColor: isChronic ? const Color(0xFF0369A1) : Colors.indigo[900],
                                      label: Text(
                                        isChronic ? '⏱️ علاج دائم (مزمن)' : '⏱️ علاج لمدة $totalDays يوم',
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                    Chip(
                                      backgroundColor: isFirstTime ? Colors.green[900] : const Color(0xFF1E293B),
                                      side: BorderSide(color: isFirstTime ? Colors.green : const Color(0xFF38BDF8)),
                                      label: Text(
                                        isFirstTime ? '🟢 أول استخدام' : '🔵 مستخدم مسبقاً (منذ $startDate)',
                                        style: TextStyle(color: isFirstTime ? Colors.greenAccent : Colors.cyanAccent, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF334155).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أدويتك محفوظة سحابياً مع سجل التاريخ ومدة العلاج، ويمكنك إضافة أي دواء جديد بالباركود.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
