import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/loading_button.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../models/cart_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedPaymentMethod = 'credit_card';
  String _selectedNetBanking = '';
  bool _isPlacingOrder = false;
  bool _isSelectingAddress = false;
  String _selectedAddressId = 'address_1';
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: cartState.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCheckoutContent(cart);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF131921),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Amazon logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.asset(
              'assets/images/amazon_logo.png',
              height: 25,
              errorBuilder: (context, error, stackTrace) => const Text(
                'amazon.in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Secure checkout
          const Text(
            'Secure checkout',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 20,
          ),
          const Spacer(),
          // Cart icon
          Consumer(
            builder: (context, ref, child) {
              final cartItemCount = ref.watch(cartItemCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9900),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Text(
            'Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Your cart is empty'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Error loading checkout'));
  }

  Widget _buildCheckoutContent(CartModel cart) {
    if (_isSelectingAddress) {
      return _buildAddressSelectionScreen(cart);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main checkout content (left side)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeliverySection(),
                const SizedBox(height: 32),
                _buildPaymentSection(),
                const SizedBox(height: 32),
                _buildReviewSection(),
              ],
            ),
          ),
        ),
        // Right sidebar - Order summary
        Container(
          width: 320,
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _buildOrderSummary(cart),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivering to Aman Singh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSelectingAddress = true;
                  });
                },
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFF007185),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sewla Kalan Chandrabani Road, Parvati vihar, DEHRADUN, UTTARAKHAND, 248001, India',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF565959),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              'Add delivery instructions',
              style: TextStyle(
                color: Color(0xFF007185),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 24),
          _buildAvailableBalance(),
          const SizedBox(height: 24),
          _buildAnotherPaymentMethod(),
        ],
      ),
    );
  }

  Widget _buildAvailableBalance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your available balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.add, size: 16, color: Color(0xFF565959)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Enter Code',
                    style: TextStyle(
                      color: Color(0xFF565959),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Color(0xFF0F1111),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnotherPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Another payment method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 16),
        _buildCreditCardOption(),
        const SizedBox(height: 16),
        _buildNetBankingOption(),
        const SizedBox(height: 16),
        _buildUPIOption(),
        const SizedBox(height: 16),
        _buildEMIOption(),
        const SizedBox(height: 16),
        _buildCODOption(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD814),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Use this payment method',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == 'credit_card' 
              ? const Color(0xFF007185) 
              : Colors.grey[300]!,
          width: _selectedPaymentMethod == 'credit_card' ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Radio<String>(
                value: 'credit_card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: const Color(0xFF007185),
              ),
              const Text(
                'Credit or debit card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F1111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment method icons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentIcon('VISA', 'assets/icons/visa.png'),
              _buildPaymentIcon('MASTERCARD', 'assets/icons/mastercard.png'),
              _buildPaymentIcon('AMEX', 'assets/icons/amex.png'),
              _buildPaymentIcon('DINERS', 'assets/icons/diners.png'),
              _buildPaymentIcon('DISCOVER', 'assets/icons/discover.png'),
              _buildPaymentIcon('RUPAY', 'assets/icons/rupay.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String name, String imagePath) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Image.asset(
          imagePath,
          width: 30,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            name,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNetBankingOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == 'net_banking' 
              ? const Color(0xFF007185) 
              : Colors.grey[300]!,
          width: _selectedPaymentMethod == 'net_banking' ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Radio<String>(
                value: 'net_banking',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: const Color(0xFF007185),
              ),
              const Text(
                'Net Banking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F1111),
                ),
              ),
            ],
          ),
          if (_selectedPaymentMethod == 'net_banking') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedNetBanking.isEmpty ? null : _selectedNetBanking,
                  hint: const Text('Choose an Option'),
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedNetBanking = value!;
                    });
                  },
                  items: ['SBI', 'HDFC', 'ICICI', 'Axis Bank', 'Other Banks']
                      .map((bank) => DropdownMenuItem(
                            value: bank,
                            child: Text(bank),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUPIOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == 'upi' 
              ? const Color(0xFF007185) 
              : Colors.grey[300]!,
          width: _selectedPaymentMethod == 'upi' ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: 'upi',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            activeColor: const Color(0xFF007185),
          ),
          const Text(
            'Other UPI Apps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F1111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEMIOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Radio<String>(
            value: 'emi',
            groupValue: null, // Disabled
            onChanged: null,
            activeColor: Colors.grey,
          ),
          const Text(
            'EMI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF565959),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCODOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Radio<String>(
                value: 'cod',
                groupValue: null, // Disabled
                onChanged: null,
                activeColor: Colors.grey,
              ),
              const Text(
                'Cash on Delivery/Pay on Delivery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF565959),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 40),
            child: Text(
              'Unavailable for this payment',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF565959),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review items and shipping',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          SizedBox(height: 16),
          // This would contain the order items review
          Text(
            'Order items will be displayed here...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF565959),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  'Use this payment method',
                  style: TextStyle(
                    color: Color(0xFF007185),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text(
                    'Items:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Delivery:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Promotion Applied:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Order Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${cart.totalPrice.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}.00',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelectionScreen(CartModel cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main address selection content (left side)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Select a delivery address',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Warning box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFFF9900),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'One-time password required at time of delivery',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1111),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Please ensure someone will be available to receive this delivery. ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0F1111),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Learn more',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF007185),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Delivery addresses section
                const Text(
                  'Delivery addresses (1)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Address list
                _buildAddressList(),
                
                const SizedBox(height: 24),
                
                // Add new address link
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Add a new delivery address',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Deliver to multiple addresses
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Deliver to multiple addresses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Deliver to this address button
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSelectingAddress = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Deliver to this address',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Gift card section
                _buildGiftCardSection(),
                
                const SizedBox(height: 32),
                
                // Review items section
                _buildReviewItemsSection(),
              ],
            ),
          ),
        ),
                 // Right sidebar - Order summary with deliver button
         Container(
           width: 320,
           height: MediaQuery.of(context).size.height - kToolbarHeight,
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(24),
             child: Container(
               decoration: BoxDecoration(
                 color: Colors.grey[50],
                 border: Border(
                   left: BorderSide(color: Colors.grey[300]!, width: 1),
                 ),
               ),
               child: _buildAddressSelectionOrderSummary(cart),
             ),
           ),
         ),
      ],
    );
  }

  Widget _buildAddressList() {
    final addresses = [
      {
        'id': 'address_1',
        'name': 'Aman Singh',
        'address': 'Sewla Kalan Chandrabani Road, Parvati vihar, DEHRADUN, UTTARAKHAND, 248001, India',
        'phone': '7618447467',
      },
    ];

    return Column(
      children: addresses.map((address) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedAddressId == address['id'] 
                  ? const Color(0xFF007185) 
                  : Colors.grey[300]!,
              width: _selectedAddressId == address['id'] ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RadioListTile<String>(
            value: address['id'] as String,
            groupValue: _selectedAddressId,
            onChanged: (value) {
              setState(() {
                _selectedAddressId = value!;
              });
            },
            activeColor: const Color(0xFF007185),
            contentPadding: const EdgeInsets.all(16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address['address'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF565959),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone number: ${address['phone']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF565959),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                                         GestureDetector(
                       onTap: () {
                         _showEditAddressDialog();
                       },
                       child: const Text(
                         'Edit address',
                         style: TextStyle(
                           fontSize: 14,
                           color: Color(0xFF007185),
                         ),
                       ),
                     ),
                    const Text(
                      ' | ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF565959),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Add delivery instructions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007185),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGiftCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Use a gift card, voucher or promo code',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF007185),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007185),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review items and shipping',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 32),
        
        // Help section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Need help? Check our ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'help pages',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                const Text(
                  ' or ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'contact us 24x7',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'When your order is placed, we\'ll send you an e-mail message acknowledging receipt of your order. If you choose to pay using an electronic payment method (credit card, debit card or net banking), you will be directed to your bank\'s website to complete your payment. Your contract to purchase an item will not be complete until we receive your electronic payment and dispatch your item. If you choose to pay using Pay on Delivery (POD), you can pay using cash/card/net banking when you receive your item.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0F1111),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'See Amazon.in\'s ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Return Policy',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                const Text(
                  '.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                         GestureDetector(
               onTap: () => context.pop(),
               child: const Text(
                 'Back to cart',
                 style: TextStyle(
                   fontSize: 13,
                   color: Color(0xFF007185),
                 ),
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSelectionOrderSummary(CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deliver to this address button at top
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isSelectingAddress = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD814),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Deliver to this address',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Order summary details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Items:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Delivery:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Promotion Applied:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Order Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${cart.totalPrice.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}.00',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditAddressDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                                         const Text(
                       'Edit your address',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.w400,
                         color: Color(0xFF0F1111),
                       ),
                     ),
                                         IconButton(
                       onPressed: () => Navigator.of(context).pop(),
                       icon: const Icon(
                         Icons.close,
                         color: Color(0xFF565959),
                         size: 24,
                       ),
                       padding: EdgeInsets.zero,
                       constraints: const BoxConstraints(),
                       splashRadius: 20,
                     ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Autofill section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Save time. Autofill your current location.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F1111),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                                             ElevatedButton(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           foregroundColor: const Color(0xFF0F1111),
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(4),
                             side: BorderSide(color: Colors.grey[300]!),
                           ),
                         ),
                         child: const Text(
                           'Autofill',
                           style: TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country/Region
                        _buildFormField(
                          'Country/Region',
                          DropdownButtonFormField<String>(
                            value: 'India',
                            decoration: _getInputDecoration(),
                            style: const TextStyle(
                              color: Color(0xFF0F1111),
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'India', 
                                child: Text(
                                  'India',
                                  style: TextStyle(
                                    color: Color(0xFF0F1111),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        
                        // Full name
                        _buildFormField(
                          'Full name (First and Last name)',
                          TextFormField(
                            initialValue: 'Aman Singh',
                            decoration: _getInputDecoration(),
                            style: _getInputTextStyle(),
                          ),
                        ),
                        
                        // Mobile number
                        _buildFormField(
                          'Mobile number',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                initialValue: '7618447467',
                                decoration: _getInputDecoration(),
                                keyboardType: TextInputType.phone,
                                style: _getInputTextStyle(),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'May be used to assist delivery',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF565959),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Pincode
                        _buildFormField(
                          'Pincode',
                          TextFormField(
                            initialValue: '248001',
                            decoration: _getInputDecoration(),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        
                        // Flat, House no.
                        _buildFormField(
                          'Flat, House no., Building, Company, Apartment',
                          TextFormField(
                            initialValue: 'Sewla Kalan Chandrabani Road',
                            decoration: _getInputDecoration(),
                          ),
                        ),
                        
                        // Area, Street
                        _buildFormField(
                          'Area, Street, Sector, Village',
                          TextFormField(
                            initialValue: 'Parvati vihar',
                            decoration: _getInputDecoration(),
                          ),
                        ),
                        
                                                 // Landmark
                         _buildFormField(
                           'Landmark',
                           TextFormField(
                             decoration: _getInputDecoration().copyWith(
                               hintText: 'E.g. near apollo hospital',
                             ),
                           ),
                         ),
                        
                        // Town/City and State
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                'Town/City',
                                TextFormField(
                                  initialValue: 'DEHRADUN',
                                  decoration: _getInputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                'State',
                                DropdownButtonFormField<String>(
                                  value: 'UTTARAKHAND',
                                  decoration: _getInputDecoration(),
                                  style: const TextStyle(
                                    color: Color(0xFF0F1111),
                                    fontSize: 13,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'UTTARAKHAND', 
                                      child: Text(
                                        'UTTARAKHAND',
                                        style: TextStyle(
                                          color: Color(0xFF0F1111),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {},
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                                                 // Make default address checkbox
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Checkbox(
                               value: false,
                               onChanged: (value) {},
                               activeColor: const Color(0xFF007185),
                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                             const SizedBox(width: 8),
                             const Expanded(
                               child: Text(
                                 'Make this my default address',
                                 style: TextStyle(
                                   fontSize: 13,
                                   color: Color(0xFF0F1111),
                                 ),
                               ),
                             ),
                           ],
                         ),
                        
                                                 // Delivery instructions
                         const SizedBox(height: 16),
                         Container(
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.grey[300]!),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: ExpansionTile(
                             title: const Text(
                               'Delivery instructions (optional)',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 color: Color(0xFF0F1111),
                               ),
                             ),
                             subtitle: const Text(
                               'Add preferences, notes, access codes and more',
                               style: TextStyle(
                                 fontSize: 11,
                                 color: Color(0xFF565959),
                               ),
                             ),
                             iconColor: const Color(0xFF007185),
                             collapsedIconColor: const Color(0xFF007185),
                             children: [
                               Padding(
                                 padding: const EdgeInsets.all(16),
                                 child: TextFormField(
                                   decoration: _getInputDecoration().copyWith(
                                     hintText: 'Add delivery instructions',
                                   ),
                                   maxLines: 3,
                                 ),
                               ),
                             ],
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Use this address button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Use this address',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 8),
        field,
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _getInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF007185), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
      ),
    );
  }

  TextStyle _getInputTextStyle() {
    return const TextStyle(
      color: Color(0xFF0F1111),
      fontSize: 13,
    );
  }
}
