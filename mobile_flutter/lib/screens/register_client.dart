import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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

  String propertyType = "HOSTEL";
  String zone = "Ayeduase";
  String prelaunchStatus = "WAITLIST";
  String paymentStatus = "UNPAID";
  String pickupDay = "Wednesday";

  File? photo;
  bool saving = false;
  String? error;

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) setState(() => photo = File(x.path));
  }

  String mapsLinkFromLatLng(double? la, double? ln) => (la == null || ln == null) ? "" : "https://maps.google.com/?q=$la,$ln";

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { saving = true; error = null; });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ecoclean_token');
    if (token == null) { setState(() { saving = false; error = "Not logged in"; }); return; }

    final la = double.tryParse(lat.text.trim());
    final ln = double.tryParse(lng.text.trim());
    final mapsLink = mapsLinkFromLatLng(la, ln);

    final uri = Uri.parse('${Api.baseUrl}/api/clients');
    final req = http.MultipartRequest("POST", uri);
    req.headers['Authorization'] = 'Bearer $token';

    req.fields['fullName'] = fullName.text.trim();
    req.fields['phone'] = phone.text.trim();
    req.fields['propertyType'] = propertyType;
    req.fields['zone'] = zone;
    req.fields['townArea'] = townArea.text.trim();
    if (la != null) req.fields['lat'] = la.toString();
    if (ln != null) req.fields['lng'] = ln.toString();
    if (mapsLink.isNotEmpty) req.fields['googleMapsLink'] = mapsLink;
    req.fields['binCount'] = binCount.text.trim();
    req.fields['landmark'] = landmark.text.trim();
    req.fields['prelaunchStatus'] = prelaunchStatus;
    req.fields['paymentStatus'] = paymentStatus;
    req.fields['pickupDay'] = pickupDay;

    if (photo != null) req.files.add(await http.MultipartFile.fromPath('buildingPhoto', photo!.path));

    try {
      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode >= 400) { setState(() { saving = false; error = body; }); return; }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client registered')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { saving = false; error = e.toString(); });
    } finally {
      setState(() => saving = false);
    }
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
                if (error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
                TextFormField(controller: fullName, decoration: const InputDecoration(labelText: 'Client full name'),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null),
                const SizedBox(height: 10),
                TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp'),
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Required' : null),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: propertyType,
                  items: const [
                    DropdownMenuItem(value: "SINGLE_HOUSE", child: Text("Single House")),
                    DropdownMenuItem(value: "COMPOUND_HOUSE", child: Text("Compound House")),
                    DropdownMenuItem(value: "APARTMENT", child: Text("Apartment")),
                    DropdownMenuItem(value: "HOSTEL", child: Text("Hostel")),
                    DropdownMenuItem(value: "SHOP", child: Text("Shop/Commercial")),
                  ],
                  onChanged: (v) => setState(() => propertyType = v.toString()),
                  decoration: const InputDecoration(labelText: 'Property Type'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: zone,
                  items: const [
                    DropdownMenuItem(value: "Anwomaso", child: Text("Anwomaso")),
                    DropdownMenuItem(value: "Ayeduase", child: Text("Ayeduase")),
                    DropdownMenuItem(value: "Kotei", child: Text("Kotei")),
                    DropdownMenuItem(value: "Boadi", child: Text("Boadi")),
                    DropdownMenuItem(value: "Appiadu", child: Text("Appiadu")),
                    DropdownMenuItem(value: "Kwamo", child: Text("Kwamo")),
                    DropdownMenuItem(value: "Aprabo", child: Text("Aprabo")),
                    DropdownMenuItem(value: "Pakyi No.1", child: Text("Pakyi No.1")),
                    DropdownMenuItem(value: "Pakyi No.2", child: Text("Pakyi No.2")),
                    DropdownMenuItem(value: "Ahenema Kokoben", child: Text("Ahenema Kokoben")),
                    DropdownMenuItem(value: "Fumesua", child: Text("Fumesua")),
                    DropdownMenuItem(value: "Ejisu", child: Text("Ejisu")),
                  ],
                  onChanged: (v) => setState(() => zone = v.toString()),
                  decoration: const InputDecoration(labelText: 'Zone/Town'),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: townArea, decoration: const InputDecoration(labelText: 'Town/Area (optional)')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: lat, decoration: const InputDecoration(labelText: 'Latitude (optional)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: lng, decoration: const InputDecoration(labelText: 'Longitude (optional)'))),
                ]),
                const SizedBox(height: 10),
                TextFormField(controller: landmark, decoration: const InputDecoration(labelText: 'Landmark/Description')),
                const SizedBox(height: 10),
                TextFormField(controller: binCount, decoration: const InputDecoration(labelText: 'Bin count'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Number required' : null),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: pickupDay,
                  items: const [
                    DropdownMenuItem(value: "Monday", child: Text("Monday")),
                    DropdownMenuItem(value: "Tuesday", child: Text("Tuesday")),
                    DropdownMenuItem(value: "Wednesday", child: Text("Wednesday")),
                    DropdownMenuItem(value: "Thursday", child: Text("Thursday")),
                    DropdownMenuItem(value: "Friday", child: Text("Friday")),
                    DropdownMenuItem(value: "Saturday", child: Text("Saturday")),
                  ],
                  onChanged: (v) => setState(() => pickupDay = v.toString()),
                  decoration: const InputDecoration(labelText: 'Assigned Pickup Day'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: prelaunchStatus,
                  items: const [
                    DropdownMenuItem(value: "WAITLIST", child: Text("Pre-Launch (Waitlist)")),
                    DropdownMenuItem(value: "RESERVED_DEPOSIT", child: Text("Reserved (Deposit)")),
                    DropdownMenuItem(value: "CONFIRMED", child: Text("Confirmed")),
                  ],
                  onChanged: (v) => setState(() => prelaunchStatus = v.toString()),
                  decoration: const InputDecoration(labelText: 'Prelaunch Status'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: paymentStatus,
                  items: const [
                    DropdownMenuItem(value: "UNPAID", child: Text("Unpaid")),
                    DropdownMenuItem(value: "DEPOSIT_PAID", child: Text("Deposit Paid")),
                    DropdownMenuItem(value: "PAID", child: Text("Paid")),
                    DropdownMenuItem(value: "PART_PAID", child: Text("Part-Paid")),
                    DropdownMenuItem(value: "OVERDUE", child: Text("Overdue")),
                  ],
                  onChanged: (v) => setState(() => paymentStatus = v.toString()),
                  decoration: const InputDecoration(labelText: 'Payment Status'),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(onPressed: pickPhoto, icon: const Icon(Icons.camera_alt),
                    label: Text(photo == null ? 'Capture building photo' : 'Photo selected'))),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity,
                  child: FilledButton(onPressed: saving ? null : submit, child: Text(saving ? 'Saving...' : 'Save Client'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
