import '../constants/app_constants.dart';

/// Utility class for form validation
class Validators {
  Validators._();

  /// Validates email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validates confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Remove all non-digit characters for validation
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for 10 digits (Indian mobile numbers)
    if (!RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }
    
    if (value.length < 5) {
      return 'Please enter a complete address';
    }
    
    return null;
  }

  /// Validates ZIP code
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your PIN code';
    }
    
    // Validate 6-digit PIN code
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit PIN code';
    }
    
    return null;
  }

  /// Validates city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your city';
    }
    return null;
  }

  /// Validates state
  static String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your state';
    }
    return null;
  }

  /// Validates landmark (optional)
  static String? validateLandmark(String? value) {
    return null; // Landmark is optional
  }

  /// Validates delivery instructions (optional)
  static String? validateDeliveryInstructions(String? value) {
    return null; // Delivery instructions are optional
  }

  /// Validates price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    double? price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    
    return null;
  }

  /// Validates quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    int? quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    return null;
  }

  /// Validates description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 1000) {
      return 'Description must be less than 1000 characters';
    }
    
    return null;
  }

  /// Validates review text
  static String? validateReview(String? value) {
    if (value == null || value.isEmpty) {
      return 'Review is required';
    }
    
    if (value.length < 5) {
      return 'Review must be at least 5 characters';
    }
    
    if (value.length > AppConstants.maxReviewCharacters) {
      return 'Review must be less than ${AppConstants.maxReviewCharacters} characters';
    }
    
    return null;
  }

  /// Validates URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional in most cases
    }
    
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Validates credit card number (basic validation)
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    // Remove spaces and dashes
    String cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Card number must contain only digits';
    }
    
    // Check length (most cards are 13-19 digits)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Invalid card number length';
    }
    
    // Luhn algorithm check
    if (!_isValidLuhn(cleaned)) {
      return 'Invalid card number';
    }
    
    return null;
  }

  /// Validates CVV
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }

  /// Validates expiry date (MM/YY format)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use MM/YY format';
    }
    
    List<String> parts = value.split('/');
    int month = int.parse(parts[0]);
    int year = int.parse('20${parts[1]}');
    
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }
    
    DateTime now = DateTime.now();
    DateTime expiry = DateTime(year, month);
    
    if (expiry.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    
    return null;
  }

  /// Validates search query
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return 'Search query cannot be empty';
    }
    
    if (value.length < 2) {
      return 'Search query must be at least 2 characters';
    }
    
    return null;
  }

  /// Helper method for Luhn algorithm
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool isEven = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  /// Validates if value is a valid number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }

  /// Validates if value is a valid positive integer
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    int? number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  /// Validates date string
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validates email or phone number
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone number is required';
    }
    if (validateEmail(value) == null || validatePhone(value) == null) {
      return null;
    }
    return 'Please enter a valid email or phone number';
  }
} 