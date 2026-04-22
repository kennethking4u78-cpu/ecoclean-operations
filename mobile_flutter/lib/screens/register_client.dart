import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullName = TextEditingController();
  final phone = TextEditingController();
  final townArea = TextEditingController();
  final lat = TextEditingController();
  final lng = TextEditingController();
  final landmark = TextEditingController();

  String propertyType = "HOSTEL";
  String zone = "Ayeduase";
  String prelaunchStatus = "WAITLIST";
  String paymentStatus = "UNPAID";

  File? photo;
  bool saving = false;
  bool gettingLocation = false;
  String? error;

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (x != null) {
      setState(() => photo = File(x.path));
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      setState(() {
        gettingLocation = true;
        error = null;
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        lat.text = position.latitude.toStringAsFixed(6);
        lng.text = position.longitude.toStringAsFixed(6);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured')),
      );
    } catch (e) {
      setState(() {
        error = e.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => gettingLocation = false);
      }
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ecoclean_token');

      if (token == null) {
        setState(() {
          saving = false;
          error = "Not logged in";
        });
        return;
      }

      final la = double.tryParse(lat.text.trim());
      final ln = double.tryParse(lng.text.trim());

      final uri = Uri.parse('${Api.baseUrl}/api/clients');

      final payload = <String, dynamic>{
        'fullName': fullName.text.trim(),
        'phone': phone.text.trim(),
        'propertyType': propertyType,
        'zone': zone,
        'townArea': townArea.text.trim(),
        'landmark': landmark.text.trim(),
        'prelaunchStatus': prelaunchStatus,
        'paymentStatus': paymentStatus,
        'monthlyFeeGhs': 0.0,
        if (la != null) 'latitude': la,
        if (ln != null) 'longitude': ln,
      };

      debugPrint('POST URL: $uri');
      debugPrint('PAYLOAD: ${jsonEncode(payload)}');

      final res = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode >= 400) {
        setState(() {
          error = data['error']?.toString() ?? res.body;
        });
        return;
      }

      if (!mounted) return;

      final clientCode = data['client']?['clientCode']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            clientCode != null && clientCode.isNotEmpty
                ? 'Client registered: $clientCode'
                : 'Client registered',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        error = 'Save failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    townArea.dispose();
    lat.dispose();
    lng.dispose();
    landmark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Client')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: fullName,
                  decoration:
                      const InputDecoration(labelText: 'Client full name'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone / WhatsApp'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().length < 8) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: propertyType,
                  items: const [
                    DropdownMenuItem(
                      value: "SINGLE_HOUSE",
                      child: Text("Single House"),
                    ),
                    DropdownMenuItem(
                      value: "COMPOUND_HOUSE",
                      child: Text("Compound House"),
                    ),
                    DropdownMenuItem(
                      value: "APARTMENT",
                      child: Text("Apartment"),
                    ),
                    DropdownMenuItem(
                      value: "HOSTEL",
                      child: Text("Hostel"),
                    ),
                    DropdownMenuItem(
                      value: "SHOP",
                      child: Text("Shop/Commercial"),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => propertyType = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Property Type'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: zone,
                  items: const [
                    DropdownMenuItem(value: "Anwomaso", child: Text("Anwomaso")),
                    DropdownMenuItem(value: "Ayeduase", child: Text("Ayeduase")),
                    DropdownMenuItem(value: "Kotei", child: Text("Kotei")),
                    DropdownMenuItem(value: "Boadi", child: Text("Boadi")),
                    DropdownMenuItem(value: "Appiadu", child: Text("Appiadu")),
                    DropdownMenuItem(value: "Kwamo", child: Text("Kwamo")),
                    DropdownMenuItem(value: "Aprabo", child: Text("Aprabo")),
                    DropdownMenuItem(
                      value: "Pakyi No.1",
                      child: Text("Pakyi No.1"),
                    ),
                    DropdownMenuItem(
                      value: "Pakyi No.2",
                      child: Text("Pakyi No.2"),
                    ),
                    DropdownMenuItem(
                      value: "Ahenema Kokoben",
                      child: Text("Ahenema Kokoben"),
                    ),
                    DropdownMenuItem(value: "Fumesua", child: Text("Fumesua")),
                    DropdownMenuItem(value: "Ejisu", child: Text("Ejisu")),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => zone = v);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Zone/Town'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: townArea,
                  decoration:
                      const InputDecoration(labelText: 'Town / Area'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: landmark,
                  decoration:
                      const InputDecoration(labelText: 'Landmark / Description'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: gettingLocation ? null : useCurrentLocation,
                    icon: gettingLocation
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      gettingLocation
                          ? 'Capturing location...'
                          : 'Use Current Location',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: lat,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: lng,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: prelaunchStatus,
                  items: const [
                    DropdownMenuItem(
                      value: "WAITLIST",
                      child: Text("Pre-Launch (Waitlist)"),
                    ),
                    DropdownMenuItem(
                      value: "RESERVED_DEPOSIT",
                      child: Text("Reserved (Deposit)"),
                    ),
                    DropdownMenuItem(
                      value: "CONFIRMED",
                      child: Text("Confirmed"),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => prelaunchStatus = v);
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: 'Prelaunch Status'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  items: const [
                    DropdownMenuItem(value: "UNPAID", child: Text("Unpaid")),
                    DropdownMenuItem(
                      value: "DEPOSIT_PAID",
                      child: Text("Deposit Paid"),
                    ),
                    DropdownMenuItem(value: "PAID", child: Text("Paid")),
                    DropdownMenuItem(
                      value: "PART_PAID",
                      child: Text("Part-Paid"),
                    ),
                    DropdownMenuItem(value: "OVERDUE", child: Text("Overdue")),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => paymentStatus = v);
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: 'Payment Status'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      photo == null
                          ? 'Capture building photo'
                          : 'Photo selected (not uploading yet)',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : submit,
                    child: Text(saving ? 'Saving...' : 'Save Client'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}