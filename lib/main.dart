import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MonitorApp());

class MonitorApp extends StatelessWidget {
  const MonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _urlController = TextEditingController(text: "http://10.0.2.2:8000/metrics");
  Map<String, dynamic>? metrics;
  bool loading = false;
  Timer? timer;

  Future<void> fetchMetrics() async {
    try {
      final res = await http.get(Uri.parse(_urlController.text)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        setState(() => metrics = jsonDecode(res.body));
      }
    } catch (_) {
      setState(() => metrics = {"status": "offline"});
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchMetrics());
  }

  @override
  void dispose() {
    timer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Server Status Monitor")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Agent URL (/metrics)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (metrics == null)
              const CircularProgressIndicator()
            else ...[
              Card(
                color: metrics!["status"] == "online" ? Colors.green.shade900 : Colors.red.shade900,
                child: ListTile(
                  title: Text("Status: ${metrics!['status'] ?? 'Unknown'}"),
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: ((metrics!['cpu_percent'] ?? 0) as num) / 100),
              Text("CPU Usage: ${metrics!['cpu_percent'] ?? 0}%"),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: ((metrics!['ram_percent'] ?? 0) as num) / 100),
              Text("RAM Usage: ${metrics!['ram_percent'] ?? 0}%"),
            ],
          ],
        ),
      ),
    );
  }
}