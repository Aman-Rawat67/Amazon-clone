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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
        title: const Text('Your Addresses'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add new address button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAddressDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a new address'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Address list
                if (user.addresses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No addresses found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first address to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...user.addresses.map((addressString) {
                    try {
                      final address = ShippingAddress.fromString(addressString);
                      return _buildAddressCard(address);
                    } catch (e) {
                      // Skip invalid address strings
                      return const SizedBox.shrink();
                    }
                  }).toList(),
              ],
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

  Widget _buildAddressCard(ShippingAddress address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.formattedAddress,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Phone: ${address.phone}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (address.deliveryInstructions?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                'Instructions: ${address.deliveryInstructions}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditAddressDialog(context, address),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteAddress(address.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                if (!address.isDefault)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _setAsDefault(address.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF232F3E),
                      ),
                      child: const Text('Set Default'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEditAddressDialog(),
    );
  }

  void _showEditAddressDialog(BuildContext context, ShippingAddress address) {
    showDialog(
      context: context,
      builder: (context) => _AddEditAddressDialog(address: address),
    );
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(userProvider).value;
        if (user != null) {
          final addresses = user.addresses.where(
            (addr) => !addr.startsWith('$addressId|'),
          ).toList();

          await ref.read(userProvider.notifier).updateUserData({
            'addresses': addresses,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
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

  Future<void> _setAsDefault(String addressId) async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider).value;
      if (user != null) {
        final addresses = user.addresses.map((addr) {
          final parts = addr.split('|');
          if (parts.length > 8) {
            if (parts[0] == addressId) {
              parts[8] = 'true';
            } else {
              parts[8] = 'false';
            }
          }
          return parts.join('|');
        }).toList();

        await ref.read(userProvider.notifier).updateUserData({
          'addresses': addresses,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default address updated'),
              backgroundColor: Colors.green,
            ),
          );
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

class _AddEditAddressDialog extends ConsumerStatefulWidget {
  final ShippingAddress? address;

  const _AddEditAddressDialog({this.address});

  @override
  ConsumerState<_AddEditAddressDialog> createState() => _AddEditAddressDialogState();
}

class _AddEditAddressDialogState extends ConsumerState<_AddEditAddressDialog> {
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(text: AppConstants.indianStates.first);
    
    // Pre-fill form if editing
    if (widget.address != null) {
      final address = widget.address!;
      _nameController.text = address.name;
      _phoneController.text = address.phone;
      
      // Parse address components
      final addressParts = address.address.split(', ');
      if (addressParts.isNotEmpty) {
        _flatController.text = addressParts[0];
        if (addressParts.length > 1) {
          _areaController.text = addressParts[1];
        }
        if (addressParts.length > 2) {
          _landmarkController.text = addressParts[2];
        }
      }
      
      _cityController.text = address.city;
      _stateController.text = address.state;
      _zipCodeController.text = address.zipCode;
      _countryController.text = address.country;
      _deliveryInstructionsController.text = address.deliveryInstructions ?? '';
      _isDefault = address.isDefault;
    }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.address == null ? 'Add New Address' : 'Edit Address',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your flat/house number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Area, Street, Sector, Village
                      TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'Area, Street, Sector, Village',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your area/street';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Landmark
                      TextFormField(
                        controller: _landmarkController,
                        decoration: const InputDecoration(
                          labelText: 'Landmark (Optional)',
                          border: OutlineInputBorder(),
                        ),
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

                      // Delivery Instructions
                      TextFormField(
                        controller: _deliveryInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery instructions (Optional)',
                          hintText: 'Add preferences, notes, access codes and more',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                    ],
                  ),
                ),
              ),
            ),

            // Save button
            const SizedBox(height: 24),
            LoadingButton(
              onPressed: _isLoading ? null : _saveAddress,
              isLoading: _isLoading,
              text: widget.address == null ? 'Add Address' : 'Update Address',
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
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(userProvider).value;
        if (user != null) {
          final addressId = widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          final newAddress = ShippingAddress(
            id: addressId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: '${_flatController.text.trim()}, ${_areaController.text.trim()}${_landmarkController.text.trim().isNotEmpty ? ', ${_landmarkController.text.trim()}' : ''}',
            city: _cityController.text.trim(),
            state: _stateController.text,
            zipCode: _zipCodeController.text.trim(),
            country: _countryController.text,
            isDefault: _isDefault,
            deliveryInstructions: _deliveryInstructionsController.text.trim().isNotEmpty 
                ? _deliveryInstructionsController.text.trim() 
                : null,
          );

          List<String> addresses = List.from(user.addresses);
          
          // Remove existing address if editing
          if (widget.address != null) {
            addresses.removeWhere((addr) => addr.startsWith('${widget.address!.id}|'));
          }
          
          // If this is the default address, remove default from others
          if (_isDefault) {
            addresses = addresses.map((addr) {
              final parts = addr.split('|');
              if (parts.length > 8 && parts[8] == 'true') {
                parts[8] = 'false';
              }
              return parts.join('|');
            }).toList();
          }
          
          // Create address string
          String addressString = '${newAddress.id}|${newAddress.name}|${newAddress.phone}|${newAddress.address}|${newAddress.city}|${newAddress.state}|${newAddress.zipCode}|${newAddress.country}|${newAddress.isDefault}';
          
          // Add delivery instructions if they exist
          if (newAddress.deliveryInstructions != null) {
            addressString += '|${newAddress.deliveryInstructions}';
          }
          
          // Add new address
          addresses.add(addressString);

          // Update user data
          await ref.read(userProvider.notifier).updateUserData({
            'addresses': addresses,
          });

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.address == null 
                    ? 'Address added successfully' 
                    : 'Address updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
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
}