import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/loading_button.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  late final TextEditingController _stateController;
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _deliveryInstructionsController = TextEditingController();
  bool _isDefault = false;
  bool _showDeliveryInstructions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(text: AppConstants.indianStates.first);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _flatController.clear();
    _areaController.clear();
    _landmarkController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipCodeController.clear();
    _countryController.text = 'India';
    _deliveryInstructionsController.clear();
    _isDefault = false;
    _showDeliveryInstructions = false;
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(userProvider).value;
        if (user != null) {
          final newAddress = ShippingAddress(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            phone: _phoneController.text,
            address: '${_flatController.text}, ${_areaController.text}${_landmarkController.text.isNotEmpty ? ', ${_landmarkController.text}' : ''}',
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipCodeController.text,
            country: _countryController.text,
            isDefault: _isDefault,
          );

          List<String> addresses = List.from(user.addresses);
          
          // If this is the default address, remove default from others
          if (_isDefault) {
            addresses = addresses.map((addr) {
              final parts = addr.split('|');
              if (parts[8] == 'true') {
                parts[8] = 'false';
              }
              return parts.join('|');
            }).toList();
          }
          
          // Convert address to string format
          String addressString = '${newAddress.id}|${newAddress.name}|${newAddress.phone}|${newAddress.address}|${newAddress.city}|${newAddress.state}|${newAddress.zipCode}|${newAddress.country}|${newAddress.isDefault}|${_deliveryInstructionsController.text}';
          
          // Add new address
          addresses.add(addressString);

          // Update user data
          await ref.read(userProvider.notifier).updateUserData({
            'addresses': addresses,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
        title: const Text('Add a new address'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please login to manage addresses'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country/Region
                  DropdownButtonFormField<String>(
                    value: 'India',
                    decoration: const InputDecoration(
                      labelText: 'Country/Region',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'India',
                        child: Text('India'),
                      ),
                    ],
                    onChanged: (value) {
                      _countryController.text = value ?? 'India';
                    },
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full name (First and Last name)',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),

                  // Mobile number
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      helperText: 'May be used to assist delivery',
                      border: OutlineInputBorder(),
                      prefixText: '+91 ',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),

                  // PIN code
                  TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: '6 digits [0-9] PIN code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateZipCode,
                  ),
                  const SizedBox(height: 16),

                  // Flat, House no., Building, etc.
                  TextFormField(
                    controller: _flatController,
                    decoration: const InputDecoration(
                      labelText: 'Flat, House no., Building, Company, Apartment',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateAddress,
                  ),
                  const SizedBox(height: 16),

                  // Area, Street, Sector, Village
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area, Street, Sector, Village',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateAddress,
                  ),
                  const SizedBox(height: 16),

                  // Landmark
                  TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Landmark (Optional)',
                      helperText: 'E.g. near apollo hospital',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateLandmark,
                  ),
                  const SizedBox(height: 16),

                  // Town/City
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Town/City',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateCity,
                  ),
                  const SizedBox(height: 16),

                  // State
                  DropdownButtonFormField<String>(
                    value: _stateController.text,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.indianStates.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _stateController.text = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your state';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Make this my default address
                  CheckboxListTile(
                    title: const Text('Make this my default address'),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  // Delivery Instructions
                  ExpansionTile(
                    title: const Text('Add delivery instructions'),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _showDeliveryInstructions = expanded;
                      });
                    },
                    children: [
                      TextFormField(
                        controller: _deliveryInstructionsController,
                        decoration: const InputDecoration(
                          hintText: 'Add preferences, notes, access codes and more',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: Validators.validateDeliveryInstructions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add address button
                  LoadingButton(
                    onPressed: _isLoading ? null : _saveAddress,
                    isLoading: _isLoading,
                    text: 'Add address',
                    backgroundColor: const Color(0xFFFFD814),
                    foregroundColor: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}