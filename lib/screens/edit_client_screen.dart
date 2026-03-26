import 'package:ecoclean_mobile/api.dart';
import 'package:flutter/material.dart';

class EditClientScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const EditClientScreen({
    super.key,
    required this.client,
  });

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController fullNameController;
  late final TextEditingController phoneController;
  late final TextEditingController townAreaController;
  late final TextEditingController landmarkController;
  late final TextEditingController notesController;
  late final TextEditingController wasteVolumeController;
  late final TextEditingController pickupFrequencyController;
  late final TextEditingController monthlyFeeController;
  late final TextEditingController binCountController;

  bool saving = false;

  final List<String> paymentStatuses = const [
    'PAID',
    'UNPAID',
    'PART_PAID',
    'DEPOSIT_PAID',
    'OVERDUE',
  ];

  final List<String> pickupDays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> propertyTypes = const [
    'SINGLE_HOUSE',
    'COMPOUND_HOUSE',
    'APARTMENT',
    'HOSTEL',
    'SHOP',
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

  String? selectedZone;
  String? selectedPickupDay;
  String? selectedPaymentStatus;
  String? selectedPropertyType;

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: widget.client['fullName']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: widget.client['phone']?.toString() ?? '',
    );
    townAreaController = TextEditingController(
      text: widget.client['townArea']?.toString() ?? '',
    );
    landmarkController = TextEditingController(
      text: widget.client['landmark']?.toString() ?? '',
    );
    notesController = TextEditingController(
      text: widget.client['notes']?.toString() ?? '',
    );
    wasteVolumeController = TextEditingController(
      text: widget.client['wasteVolume']?.toString() ?? '',
    );
    pickupFrequencyController = TextEditingController(
      text: widget.client['pickupFrequency']?.toString() ?? '',
    );
    monthlyFeeController = TextEditingController(
      text: widget.client['monthlyFeeGhs']?.toString() ?? '',
    );
    binCountController = TextEditingController(
      text: widget.client['binCount']?.toString() ?? '',
    );

    selectedZone = _validOrNull(widget.client['zone']?.toString(), zones);
    selectedPickupDay = _validOrNull(
      widget.client['pickupDay']?.toString(),
      pickupDays,
    );
    selectedPaymentStatus = _validOrNull(
          widget.client['paymentStatus']?.toString().toUpperCase(),
          paymentStatuses,
        ) ??
        'UNPAID';
    selectedPropertyType = _validOrNull(
          widget.client['propertyType']?.toString(),
          propertyTypes,
        ) ??
        'SINGLE_HOUSE';
  }

  String? _validOrNull(String? value, List<String> options) {
    if (value == null || value.trim().isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    townAreaController.dispose();
    landmarkController.dispose();
    notesController.dispose();
    wasteVolumeController.dispose();
    pickupFrequencyController.dispose();
    monthlyFeeController.dispose();
    binCountController.dispose();
    super.dispose();
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

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  InputDecoration _input(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    );
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _nullableInt(
    TextEditingController controller, {
    String? fieldName,
  }) {
    final value = controller.text.trim();

    if (value.isEmpty) return null;

    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw Exception(
        fieldName == null
            ? 'Please enter a valid number'
            : '$fieldName must be a valid number',
      );
    }

    return parsed;
  }

  Future<void> _save() async {
    if (saving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      saving = true;
    });

    try {
      final token = await Api.getSavedToken();

      if (token.trim().isEmpty) {
        throw Exception('Missing login token');
      }

      final clientId = widget.client['id']?.toString();
      if (clientId == null || clientId.trim().isEmpty) {
        throw Exception('Client ID is missing');
      }

      final payload = <String, dynamic>{
        'fullName': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'zone': selectedZone,
        'pickupDay': selectedPickupDay,
        'paymentStatus': selectedPaymentStatus,
        'propertyType': selectedPropertyType,
        'townArea': _nullableText(townAreaController),
        'landmark': _nullableText(landmarkController),
        'notes': _nullableText(notesController),
        'wasteVolume': _nullableText(wasteVolumeController),
        'pickupFrequency': _nullableText(pickupFrequencyController),
        'monthlyFeeGhs': _nullableInt(
          monthlyFeeController,
          fieldName: 'Monthly fee',
        ),
        'binCount': _nullableInt(
          binCountController,
          fieldName: 'Bin count',
        ),
      };

      final result = await Api.updateClient(token, clientId, payload);

      if (!mounted) return;

      _showSuccess(
        result['message']?.toString() ?? 'Client updated successfully',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Client'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: fullNameController,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
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
                  enabled: !saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Phone'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPropertyType,
                  decoration: _input('Property Type'),
                  items: propertyTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() {
                            selectedPropertyType = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Property type is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedZone,
                  decoration: _input('Zone'),
                  isExpanded: true,
                  items: zones.map((zone) {
                    return DropdownMenuItem<String>(
                      value: zone,
                      child: Text(
                        zone,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() {
                            selectedZone = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Zone is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: townAreaController,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Town / Area'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: landmarkController,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Landmark'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPickupDay,
                  decoration: _input('Pickup Day'),
                  items: pickupDays.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() {
                            selectedPickupDay = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentStatus,
                  decoration: _input('Payment Status'),
                  items: paymentStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() {
                            selectedPaymentStatus = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: binCountController,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Bin Count', hint: '1'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: monthlyFeeController,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Monthly Fee (GHS)', hint: '120'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: wasteVolumeController,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Waste Volume'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pickupFrequencyController,
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Pickup Frequency'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  enabled: !saving,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!saving) {
                      _save();
                    }
                  },
                  decoration: _input('Notes'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
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
                      saving ? 'Saving...' : 'Save Changes',
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