import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';

class CreateClientScreen extends StatefulWidget {
  const CreateClientScreen({super.key});

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool loading = false;
  bool gettingLocation = false;
  bool pickingImage = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final townController = TextEditingController();
  final landmarkController = TextEditingController();

  String pickupDay = 'Monday';
  String paymentStatus = 'PAID';
  String? selectedZone;
  String? detectedZone;

  double? lat;
  double? lng;
  String? googleMapsLink;

  File? clientImage;

  final List<String> pickupDays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> paymentStatuses = const [
    'PAID',
    'UNPAID',
  ];

  final List<String> zones = const [
    'Zone 1 - EcoClean Ghana HQ – Anwomaso',
    'Zone 2 – Kwamo',
    'Zone 3- Aprabo, Kumasi',
    'Zone 4 - Appiadu',
    'Zone 7 - Oduom',
    'Zone 8 - Ayeduase',
    'Zone 9 - Kotei',
    'Zone 10 - Boadi',
    'Zone 11 - Fumesua',
    'Zone 12 - Ejisu',
    'Zone 13 Kentinkrono Nsenie',
    'Zone 14 Ayigya',
    'Zone 15 Appiadu kokoben',
    'Zone 16 Deduako',
    'Zone 17 Domeabra',
    'Zone 18 Apromase home',
    'Zone 19 Emena',
    'Zone 20 Bomso',
    'Zone 21 Susanso Kingdom Hall',
    'Zone 22 Ahinsan Estate',
    'Zone 23 Gyinyase Kusikyi Royal Palace',
  ];

  final Map<String, Map<String, double>> zoneCenters = const {
    'Zone 1 - EcoClean Ghana HQ – Anwomaso': {
      'lat': 6.692349,
      'lng': -1.530791,
    },
    'Zone 2 – Kwamo': {
      'lat': 6.7126075,
      'lng': -1.4993988,
    },
    'Zone 3- Aprabo, Kumasi': {
      'lat': 6.6314605,
      'lng': -1.5808896,
    },
    'Zone 4 - Appiadu': {
      'lat': 6.6641353,
      'lng': -1.5281253,
    },
    'Zone 7 - Oduom': {
      'lat': 6.6928115,
      'lng': -1.5477592,
    },
    'Zone 8 - Ayeduase': {
      'lat': 6.6744538,
      'lng': -1.542493,
    },
    'Zone 9 - Kotei': {
      'lat': 6.6642672,
      'lng': -1.55903,
    },
    'Zone 10 - Boadi': {
      'lat': 6.6666035,
      'lng': -1.6163247,
    },
    'Zone 11 - Fumesua': {
      'lat': 6.7109461,
      'lng': -1.5172315,
    },
    'Zone 12 - Ejisu': {
      'lat': 6.7216495,
      'lng': -1.4767614,
    },
    'Zone 13 Kentinkrono Nsenie': {
      'lat': 6.7021411,
      'lng': -1.5488892,
    },
    'Zone 14 Ayigya': {
      'lat': 6.6930838,
      'lng': -1.5766843,
    },
    'Zone 15 Appiadu kokoben': {
      'lat': 6.6680582,
      'lng': -1.5112245,
    },
    'Zone 16 Deduako': {
      'lat': 6.6520563,
      'lng': -1.5462877,
    },
    'Zone 17 Domeabra': {
      'lat': 6.6788887,
      'lng': -1.5099705,
    },
    'Zone 18 Apromase home': {
      'lat': 6.6761725,
      'lng': -1.4930903,
    },
    'Zone 19 Emena': {
      'lat': 6.666667,
      'lng': -1.533333,
    },
    'Zone 20 Bomso': {
      'lat': 6.2697092,
      'lng': -0.7853827,
    },
    'Zone 21 Susanso Kingdom Hall': {
      'lat': 6.6823031,
      'lng': -1.5870751,
    },
    'Zone 22 Ahinsan Estate': {
      'lat': 6.6666035,
      'lng': -1.6163246,
    },
    'Zone 23 Gyinyase Kusikyi Royal Palace': {
      'lat': 6.6609331,
      'lng': -1.5754541,
    },
  };

  @override
  void initState() {
    super.initState();
    if (zones.isNotEmpty) {
      selectedZone = zones.first;
      _applyZoneCenter(zones.first, silent: true);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    townController.dispose();
    landmarkController.dispose();
    super.dispose();
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _buildMapLink(double latValue, double lngValue) {
    return 'https://www.google.com/maps?q=$latValue,$lngValue';
  }

  void _applyZoneCenter(String zone, {bool silent = false}) {
    final coords = zoneCenters[zone];
    if (coords == null) return;

    final zoneLat = coords['lat'];
    final zoneLng = coords['lng'];

    if (zoneLat == null || zoneLng == null) return;

    setState(() {
      selectedZone = zone;
      detectedZone = zone;
      lat = zoneLat;
      lng = zoneLng;
      googleMapsLink = _buildMapLink(zoneLat, zoneLng);
    });

    if (!silent) {
      _showSuccess('Zone center applied');
    }
  }

  String? _findNearestZone(double currentLat, double currentLng) {
    String? nearestZone;
    double? nearestDistance;

    for (final entry in zoneCenters.entries) {
      final zoneLat = entry.value['lat'];
      final zoneLng = entry.value['lng'];

      if (zoneLat == null || zoneLng == null) continue;

      final distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        zoneLat,
        zoneLng,
      );

      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
        nearestZone = entry.key;
      }
    }

    return nearestZone;
  }

  Future<void> _captureLocation() async {
    if (gettingLocation || loading) return;

    setState(() {
      gettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please turn on device location');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it in phone settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final capturedLat = position.latitude;
      final capturedLng = position.longitude;
      final nearestZone = _findNearestZone(capturedLat, capturedLng);

      if (!mounted) return;

      setState(() {
        lat = capturedLat;
        lng = capturedLng;
        googleMapsLink = _buildMapLink(capturedLat, capturedLng);

        if (nearestZone != null) {
          selectedZone = nearestZone;
          detectedZone = nearestZone;
        }
      });

      _showSuccess(
        nearestZone != null
            ? 'GPS captured. Nearest zone selected automatically.'
            : 'Exact GPS captured successfully.',
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        gettingLocation = false;
      });
    }
  }

  Future<void> _captureClientPhoto() async {
    if (pickingImage || loading) return;

    setState(() {
      pickingImage = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 55,
        maxWidth: 1280,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      setState(() {
        clientImage = File(pickedFile.path);
      });

      _showSuccess('Client photo captured');
    } catch (_) {
      _showError('Failed to capture image');
    } finally {
      if (!mounted) return;
      setState(() {
        pickingImage = false;
      });
    }
  }

  Future<void> _openMapLink() async {
    if (googleMapsLink == null || googleMapsLink!.trim().isEmpty) {
      _showError('No map link available');
      return;
    }

    final uri = Uri.parse(googleMapsLink!);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open map link');
    }
  }

  Future<void> _createClient() async {
    if (loading) return;
    if (!_formKey.currentState!.validate()) return;

    if (selectedZone == null || selectedZone!.trim().isEmpty) {
      _showError('Please select a zone');
      return;
    }

    if (lat == null || lng == null) {
      _showError('Please capture location or use zone center first');
      return;
    }

    if (clientImage == null) {
      _showError('Please take a client photo before submitting');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final token = await Api.getSavedToken();

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final payload = <String, dynamic>{
        'fullName': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'pickupDay': pickupDay,
        'paymentStatus': paymentStatus,
        'townArea': townController.text.trim(),
        'landmark': landmarkController.text.trim(),
        'zone': selectedZone,
        'lat': lat,
        'lng': lng,
        'googleMapsLink': googleMapsLink,
      };

      final result = await Api.registerClient(
        token,
        payload,
        imagePath: clientImage!.path,
      );

      if (!mounted) return;

      _showSuccess(
        result['message']?.toString() ?? 'Client created successfully',
      );

      Navigator.pop(context, true);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');

      _showError(
        message.isEmpty
            ? 'Failed to create client. Please try again.'
            : message,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  InputDecoration _input(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
    );
  }

  Widget _locationCard() {
    final hasCoords = lat != null && lng != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Use zone center as fallback, or capture exact GPS from the phone.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (loading || selectedZone == null)
                        ? null
                        : () => _applyZoneCenter(selectedZone!),
                    icon: const Icon(Icons.location_city),
                    label: const Text(
                      'Use Zone Center',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (loading || gettingLocation)
                        ? null
                        : _captureLocation,
                    icon: gettingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      gettingLocation ? 'Capturing...' : 'Capture GPS',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (detectedZone != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Detected nearest zone: $detectedZone',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (hasCoords) ...[
              const SizedBox(height: 14),
              Text('Latitude: ${lat!.toStringAsFixed(6)}'),
              const SizedBox(height: 4),
              Text('Longitude: ${lng!.toStringAsFixed(6)}'),
            ],
            if (googleMapsLink != null && googleMapsLink!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                googleMapsLink!,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openMapLink,
                icon: const Icon(Icons.map),
                label: const Text('Open Map Preview'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Capture a photo of the client location, gate, or landmark.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (loading || pickingImage) ? null : _captureClientPhoto,
                icon: pickingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  pickingImage ? 'Opening Camera...' : 'Take Client Photo',
                ),
              ),
            ),
            if (clientImage != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  clientImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (loading || pickingImage)
                          ? null
                          : _captureClientPhoto,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake Photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () {
                              setState(() {
                                clientImage = null;
                              });
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Photo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _zoneDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedZone,
      isExpanded: true,
      decoration: _input('Zone'),
      items: zones.map((zone) {
        return DropdownMenuItem<String>(
          value: zone,
          child: Text(
            zone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return zones.map((zone) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              zone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      onChanged: loading
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                selectedZone = value;
                detectedZone = value;
              });
              _applyZoneCenter(value, silent: true);
            },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Zone is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Client'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Client',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Register a client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create a client record for pickups, payments, and routing.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: fullNameController,
                  enabled: !loading,
                  decoration: _input('Full Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  enabled: !loading,
                  keyboardType: TextInputType.phone,
                  decoration: _input('Phone', hint: '0240000000'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: pickupDay,
                  isExpanded: true,
                  decoration: _input('Pickup Day'),
                  items: pickupDays.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            pickupDay = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  isExpanded: true,
                  decoration: _input('Payment Status'),
                  items: paymentStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            paymentStatus = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: townController,
                  enabled: !loading,
                  decoration: _input('Town / Area'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Town / Area is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: landmarkController,
                  enabled: !loading,
                  decoration: _input('Landmark'),
                ),
                const SizedBox(height: 16),
                _zoneDropdown(),
                const SizedBox(height: 16),
                _locationCard(),
                const SizedBox(height: 16),
                _photoCard(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : _createClient,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      loading ? 'Creating...' : 'Create Client',
                    ),
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