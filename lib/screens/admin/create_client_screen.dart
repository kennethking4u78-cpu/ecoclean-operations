import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateClientScreen extends StatefulWidget {
  final String token;

  const CreateClientScreen({
    super.key,
    required this.token,
  });

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final String baseUrl = "http://192.168.1.67:4000";

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController zoneController = TextEditingController();
  final TextEditingController townController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String pickupDay = "Monday";
  String propertyType = "SINGLE_HOUSE";

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    zoneController.dispose();
    townController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> createClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/clients"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "fullName": nameController.text.trim(),
          "phone": phoneController.text.trim(),
          "zone": zoneController.text.trim(),
          "townArea": townController.text.trim(),
          "pickupDay": pickupDay,
          "propertyType": propertyType,
          "notes": notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Client created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "Failed to create client"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Client"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: inputDecoration("Full Name"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Full name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: inputDecoration("Phone"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Phone is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: zoneController,
              decoration: inputDecoration("Zone"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Zone is required";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: townController,
              decoration: inputDecoration("Town Area"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: pickupDay,
              decoration: inputDecoration("Pickup Day"),
              items: const [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
              ]
                  .map(
                    (day) => DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    pickupDay = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: propertyType,
              decoration: inputDecoration("Property Type"),
              items: const [
                "SINGLE_HOUSE",
                "COMPOUND_HOUSE",
                "APARTMENT",
                "HOSTEL",
                "SHOP",
              ]
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    propertyType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: inputDecoration("Notes (Optional)"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : createClient,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Create Client"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}