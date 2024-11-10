import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(BookApp());
}

class BookApp extends StatefulWidget {
  @override
  State<BookApp> createState() => _BookAppState();

  Future<List<Service>> fetchServices(String email) async {
    final response = await http.post(
      Uri.parse("https://api.thenotary.app/customer/login"),
      body: {'email': email},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final services = data["data"]["availableServices"]["services"];
      return (services as List)
          .map((service) => Service.fromJson(service))
          .toList();
    } else {
      throw Exception("Failed to load services");
    }
  }
}

class _BookAppState extends State<BookApp> {
  final TextEditingController _emailController = TextEditingController();
  List<Service> _services = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty && _services.isEmpty) {
        _fetchAndDisplayServices();
      }
    });
  }

  void _fetchAndDisplayServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await widget.fetchServices(_emailController.text);
      setState(() => _services = services);
    } catch (e) {
      print("Error fetching services: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getServiceIdText(String serviceId) {
    switch (serviceId) {
      case "LSA_ONLINE":
        return "Real Estate Notarization";
      case "LSA_OFFLINE":
        return "Real Estate Offline Notarization";
      default:
        return serviceId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Book Services")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter email to load services',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Expanded(
                      child: _services.isNotEmpty
                          ? ListView.builder(
                              itemCount: _services.length,
                              itemBuilder: (context, index) {
                                final service = _services[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(service.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                                _getServiceIdText(
                                                    service.serviceId),
                                                style: TextStyle(
                                                    color: Colors.grey[700])),
                                          ],
                                        ),
                                        Text("\$${service.cost}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Text("No services found")),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class Service {
  final String name;
  final String description;
  final String serviceId;
  final String cost;

  Service({
    required this.name,
    required this.description,
    required this.serviceId,
    required this.cost,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['serviceName'] ?? "Unnamed Service",
      description: json['description'] ?? "",
      serviceId: json['serviceId'] ?? "Unknown ID",
      cost: json['cost']?.toString() ?? "0",
    );
  }
}
