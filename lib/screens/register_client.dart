import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final binCount = TextEditingController(text: "1");

  String propertyType = "APARTMENT";
  String zone = "Tema";
  String prelaunchStatus = "CONFIRMED";
  String paymentStatus = "PAID";
  String pickupDay = "Sunday";

  File? photo;
  bool saving = false;
  String? error;

  static const pickupDays = [
    "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"
  ];

  static const zones = [
    "Tema","Tema Community 25","Devtraco Courts","Community 25",
    "Sakumono","Spintex","Teshie","Nungua","Ashaiman",
    "East Legon","Airport","Cantonments","Labone","Osu",
    "Adenta","Madina","Kasoa",
    "Anwomaso","Ayeduase","Kotei","Boadi","Appiadu","Kwamo",
    "Aprabo","Pakyi No.1","Pakyi No.2","Ahenema Kokoben","Fumesua","Ejisu"
  ];

  @override
  void initState() {
    super.initState();
    townArea.text = "Community 25 / Devtraco Courts";
    landmark.text = "Devtraco Courts, Tema Community 25";
  }

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    townArea.dispose();
    lat.dispose();
    lng.dispose();
    landmark.dispose();
    binCount.dispose();
    super.dispose();
  }

  /* =========================
     CAMERA PHOTO
  ========================= */

  Future<void> pickPhoto() async {
    final picker = ImagePicker();

    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (x != null) {
      setState(() {
        photo = File(x.path);
      });
    }
  }

  /* =========================
     GPS LOCATION
  ========================= */

  Future<void> getGPSLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable GPS on your phone")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    lat.text = position.latitude.toString();
    lng.text = position.longitude.toString();

    setState(() {});
  }

  /* =========================
     CLIENT CODE
  ========================= */

  String generateClientCode() {
    final now = DateTime.now();
    return "EC${now.microsecondsSinceEpoch.toString().substring(8)}";
  }

  /* =========================
     MAP LINK
  ========================= */

  String mapsLink(double? la, double? ln) {
    if (la == null || ln == null) return "";
    return "https://www.google.com/maps?q=$la,$ln";
  }

  /* =========================
     OPEN GOOGLE MAP
  ========================= */

  Future<void> openMap() async {

    final la = double.tryParse(lat.text);
    final ln = double.tryParse(lng.text);

    if (la == null || ln == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture GPS location first")),
      );
      return;
    }

    final Uri uri = Uri.parse("https://www.google.com/maps?q=$la,$ln");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open Google Maps");
    }
  }

  /* =========================
     ERROR PARSER
  ========================= */

  String extractError(String body) {

    if (body.trim().isEmpty) return "Server error";

    try {
      final match = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(body);
      if (match != null) return match.group(1)!;
    } catch (_) {}

    return body;
  }

  /* =========================
     SUBMIT CLIENT
  ========================= */

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
          error = "Not logged in";
          saving = false;
        });
        return;
      }

      final la = double.tryParse(lat.text.trim());
      final ln = double.tryParse(lng.text.trim());

      final uri = Uri.parse("${Api.baseUrl}/api/clients");

      final req = http.MultipartRequest("POST", uri);

      req.headers['Authorization'] = "Bearer $token";

      req.fields.addAll({
        "clientCode": generateClientCode(),
        "fullName": fullName.text.trim(),
        "phone": phone.text.trim(),
        "propertyType": propertyType,
        "zone": zone,
        "binCount": binCount.text.trim(),
        "prelaunchStatus": prelaunchStatus,
        "paymentStatus": paymentStatus,
        "pickupDay": pickupDay,
      });

      if (townArea.text.isNotEmpty) {
        req.fields['townArea'] = townArea.text.trim();
      }

      if (landmark.text.isNotEmpty) {
        req.fields['landmark'] = landmark.text.trim();
      }

      if (la != null) req.fields['lat'] = la.toString();
      if (ln != null) req.fields['lng'] = ln.toString();

      final link = mapsLink(la, ln);
      if (link.isNotEmpty) req.fields['googleMapsLink'] = link;

      if (photo != null && await photo!.exists()) {
        req.files.add(
          await http.MultipartFile.fromPath(
            "buildingPhoto",
            photo!.path,
          ),
        );
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode >= 400) {

        setState(() {
          saving = false;
          error = extractError(body);
        });

        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Client registered successfully")),
      );

      Navigator.pop(context);

    } catch (e) {

      setState(() {
        error = e.toString().replaceFirst("Exception: ", "");
      });

    } finally {

      if (mounted) {
        setState(() => saving = false);
      }

    }
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(labelText: label);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Register Client"),
      ),

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
                  decoration: fieldDecoration("Client full name"),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? "Required" : null,
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: phone,
                  decoration: fieldDecoration("Phone / WhatsApp"),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.trim().length < 8 ? "Required" : null,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: propertyType,
                  decoration: fieldDecoration("Property Type"),
                  items: const [
                    DropdownMenuItem(value: "SINGLE_HOUSE", child: Text("Single House")),
                    DropdownMenuItem(value: "COMPOUND_HOUSE", child: Text("Compound House")),
                    DropdownMenuItem(value: "APARTMENT", child: Text("Apartment")),
                    DropdownMenuItem(value: "HOSTEL", child: Text("Hostel")),
                    DropdownMenuItem(value: "SHOP", child: Text("Shop/Commercial")),
                  ],
                  onChanged: (v) => setState(() => propertyType = v!),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: zone,
                  decoration: fieldDecoration("Zone/Town"),
                  items: zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                  onChanged: (v) => setState(() => zone = v!),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: townArea,
                  decoration: fieldDecoration("Town/Area"),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Expanded(
                      child: TextFormField(
                        controller: lat,
                        decoration: fieldDecoration("Latitude"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        controller: lng,
                        decoration: fieldDecoration("Longitude"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: getGPSLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text("Get GPS"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: openMap,
                        icon: const Icon(Icons.map),
                        label: const Text("Open Map"),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: landmark,
                  decoration: fieldDecoration("Landmark"),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: binCount,
                  decoration: fieldDecoration("Bin count"),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? "") == null ? "Number required" : null,
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: pickupDay,
                  decoration: fieldDecoration("Pickup Day"),
                  items: pickupDays.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),
                  onChanged:(v)=>setState(()=>pickupDay=v!),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      photo == null
                          ? "Capture building photo"
                          : "Photo selected",
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : submit,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save Client"),
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